#!/bin/bash

# ==============================================================================
# SCRIPT DE DEPLOY COMPLETO - GOOGLE CLOUD
# ==============================================================================
# Este script automatiza o deploy de toda a infraestrutura no Google Cloud.
#
# Uso: ./deploy.sh

set -e

echo "═══════════════════════════════════════════════════"
echo "   INICIANDO DEPLOY NO GOOGLE CLOUD"
echo "═══════════════════════════════════════════════════"

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações (substitua pelos valores do seu projeto)
PROJECT_ID="sis-gerenciamento-de-feedbacks"
REGION="us-central1"

echo -e "${BLUE}Configurando projeto: ${PROJECT_ID}${NC}"
gcloud config set project ${PROJECT_ID}

# ==============================================================================
# 1. CRIAR CLOUD SQL INSTANCE (PostgreSQL)
# ==============================================================================
echo -e "\n${YELLOW}[1/6] Criando Cloud SQL Instance...${NC}"

if gcloud sql instances describe feedbackdb 2>/dev/null; then
    echo "✓ Cloud SQL instance já existe"
else
    echo "Criando nova instância Cloud SQL..."
    gcloud sql instances create feedbackdb \
        --database-version=POSTGRES_15 \
        --tier=db-f1-micro \
        --region=${REGION} \
        --root-password=your-secure-password

    echo "Criando banco de dados..."
    gcloud sql databases create feedbackdb \
        --instance=feedbackdb

    echo "Criando usuário..."
    gcloud sql users create feedbackuser \
        --instance=feedbackdb \
        --password=your-secure-password

    echo -e "${GREEN}✓ Cloud SQL configurado com sucesso${NC}"
fi

# ==============================================================================
# 2. BUILD DA APLICAÇÃO SPRING BOOT
# ==============================================================================
echo -e "\n${YELLOW}[2/6] Compilando aplicação Spring Boot...${NC}"
./mvnw clean package -DskipTests
echo -e "${GREEN}✓ Build concluído${NC}"

# ==============================================================================
# 3. DEPLOY NO APP ENGINE
# ==============================================================================
echo -e "\n${YELLOW}[3/6] Fazendo deploy no App Engine...${NC}"
gcloud app deploy --quiet
echo -e "${GREEN}✓ App Engine deploy concluído${NC}"

# ==============================================================================
# 4. DEPLOY DA CLOUD FUNCTION DE NOTIFICAÇÃO
# ==============================================================================
echo -e "\n${YELLOW}[4/6] Fazendo deploy da Cloud Function de Notificação...${NC}"
cd cloud-functions/notification-function
gcloud functions deploy notifyAdmin \
    --runtime nodejs20 \
    --trigger-http \
    --allow-unauthenticated \
    --entry-point notifyUrgentFeedback \
    --region ${REGION}
cd ../..
echo -e "${GREEN}✓ Cloud Function de Notificação deploy concluído${NC}"

# ==============================================================================
# 5. DEPLOY DA CLOUD FUNCTION DE RELATÓRIO
# ==============================================================================
echo -e "\n${YELLOW}[5/6] Fazendo deploy da Cloud Function de Relatório...${NC}"

# Criar tópico Pub/Sub se não existir
if gcloud pubsub topics describe weekly-report 2>/dev/null; then
    echo "✓ Tópico Pub/Sub já existe"
else
    gcloud pubsub topics create weekly-report
fi

cd cloud-functions/report-function
gcloud functions deploy generateReport \
    --runtime nodejs20 \
    --trigger-topic weekly-report \
    --entry-point generateWeeklyReport \
    --region ${REGION}
cd ../..
echo -e "${GREEN}✓ Cloud Function de Relatório deploy concluído${NC}"

# ==============================================================================
# 6. CONFIGURAR CLOUD SCHEDULER (Relatório Semanal)
# ==============================================================================
echo -e "\n${YELLOW}[6/6] Configurando Cloud Scheduler...${NC}"

# Criar job agendado
if gcloud scheduler jobs describe weekly-report-job 2>/dev/null; then
    echo "✓ Job agendado já existe"
else
    gcloud scheduler jobs create pubsub weekly-report-job \
        --schedule="0 8 * * 1" \
        --topic=weekly-report \
        --message-body='{"action":"generate_report"}' \
        --time-zone="America/Sao_Paulo"
    echo -e "${GREEN}✓ Job agendado criado (toda segunda-feira às 08:00)${NC}"
fi

# ==============================================================================
# FINALIZAÇÃO
# ==============================================================================
echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✓ DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"

# Obter URLs
APP_URL=$(gcloud app describe --format="value(defaultHostname)")
NOTIFICATION_URL=$(gcloud functions describe notifyAdmin --region=${REGION} --format="value(httpsTrigger.url)")

echo -e "\n${BLUE}📌 URLs dos Serviços:${NC}"
echo -e "   API Principal: https://${APP_URL}"
echo -e "   Cloud Function (Notificação): ${NOTIFICATION_URL}"
echo ""
echo -e "${BLUE}📊 Monitoramento:${NC}"
echo -e "   Logs: gcloud app logs tail -s default"
echo -e "   Metrics: https://console.cloud.google.com/monitoring"
echo ""
echo -e "${BLUE}🔐 Credenciais de Teste:${NC}"
echo -e "   Admin: admin@feedback.com / admin123"
echo -e "   Aluno: maria.silva@aluno.com / maria123"
echo ""
