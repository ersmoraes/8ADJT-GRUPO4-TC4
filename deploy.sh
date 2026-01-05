#!/bin/bash

# ==============================================================================
# SCRIPT DE DEPLOY COMPLETO - GOOGLE CLOUD
# ==============================================================================
# Uso: chmod +x deploy.sh
#      ./deploy.sh
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ID="sis-gerenciamento-de-feedbacks"
REGION="us-central1"
SERVICE_NAME="feedback-backend"

echo "═══════════════════════════════════════════════════"
echo "        INICIANDO DEPLOY NO GOOGLE CLOUD"
echo "═══════════════════════════════════════════════════"

echo -e "${BLUE}Selecionando Projeto...${NC}"
gcloud config set project ${PROJECT_ID}

# ==============================================================================
# 1) BUILD DO BACKEND
# ==============================================================================
echo -e "\n${YELLOW}[1/7] Build do Backend Spring Boot...${NC}"
./mvnw clean package -DskipTests
echo -e "${GREEN}✓ Build concluído${NC}"

# ==============================================================================
# 2) DEPLOY CLOUD RUN - API PRINCIPAL
# ==============================================================================
echo -e "\n${YELLOW}[2/7] Deploy Cloud Run Backend...${NC}"

gcloud run deploy ${SERVICE_NAME} \
  --image gcr.io/${PROJECT_ID}/${SERVICE_NAME} \
  --source . \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated

echo -e "${GREEN}✓ Cloud Run deploy concluído${NC}"

# ==============================================================================
# 3) CLOUD FUNCTION - NOTIFICAÇÃO
# ==============================================================================
echo -e "\n${YELLOW}[3/7] Deploy Notification Function...${NC}"

cd cloud-functions/notification-function

gcloud functions deploy notifyadmin \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region ${REGION}

cd ../..

echo -e "${GREEN}✓ Notification Function deploy concluído${NC}"

# ==============================================================================
# 4) CRIAR TÓPICO PUB/SUB - RELATÓRIO
# ==============================================================================
echo -e "\n${YELLOW}[4/7] Verificando Pub/Sub...${NC}"

if gcloud pubsub topics describe weekly-report >/dev/null 2>&1 ; then
  echo "✓ Topic weekly-report já existe"
else
  gcloud pubsub topics create weekly-report
  echo "✓ Topic weekly-report criado"
fi

# ==============================================================================
# 5) CLOUD FUNCTION - RELATÓRIO SEMANAL (PUBSUB)
# ==============================================================================
echo -e "\n${YELLOW}[5/7] Deploy Weekly Report Function...${NC}"

cd cloud-functions/report-function

gcloud functions deploy generatereport \
  --runtime nodejs20 \
  --trigger-topic=weekly-report \
  --entry-point=generateWeeklyReport \
  --region ${REGION}

echo -e "${GREEN}✓ Weekly Report Function deploy concluído${NC}"

# ==============================================================================
# 6) CLOUD FUNCTION - RELATÓRIO MANUAL (HTTP)
# ==============================================================================
echo -e "\n${YELLOW}[6/7] Deploy Manual Report HTTP Function...${NC}"

gcloud functions deploy reporthttp \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=generateManualReport \
  --region ${REGION}

cd ../..

echo -e "${GREEN}✓ Manual Report HTTP Function deploy concluído${NC}"

# ==============================================================================
# 7) CLOUD SCHEDULER
# ==============================================================================
echo -e "\n${YELLOW}[7/7] Configurando Cloud Scheduler...${NC}"

if gcloud scheduler jobs describe weekly-report-job >/dev/null 2>&1 ; then
  echo "✓ Scheduler job já existe"
else
  gcloud scheduler jobs create pubsub weekly-report-job \
    --schedule="0 8 * * 1" \
    --topic=weekly-report \
    --message-body="generate" \
    --time-zone="America/Sao_Paulo"
  echo "✓ Scheduler criado"
fi

# ==============================================================================
# FINALIZAÇÃO
# ==============================================================================
echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}            DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"

BACKEND_URL=$(gcloud run services describe ${SERVICE_NAME} --region ${REGION} --format="value(status.url)")
NOTIFY_URL=$(gcloud functions describe notifyadmin --region ${REGION} --format="value(httpsTrigger.url)")
WEEKLY_URL="Pub/Sub"
MANUAL_URL=$(gcloud functions describe reporthttp --region ${REGION} --format="value(httpsTrigger.url)")

echo -e "\n${BLUE}🔗 URLs Final:${NC}"
echo "Backend:             $BACKEND_URL"
echo "Notify Function:     $NOTIFY_URL"
echo "Weekly Report:       (via Pub/Sub)"
echo "Manual Report HTTP:  $MANUAL_URL"

echo -e "\n${BLUE}📊 Monitoramento:${NC}"
echo "Logs Cloud Run: https://console.cloud.google.com/run"
echo "Logs Functions: https://console.cloud.google.com/functions"
echo "Pub/Sub: https://console.cloud.google.com/pubsub"
echo "Scheduler: https://console.cloud.google.com/scheduler"

echo ""
