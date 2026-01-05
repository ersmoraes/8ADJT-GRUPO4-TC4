#!/bin/bash

# ==============================================================================
# SCRIPT DE ENCERRAMENTO - GOOGLE CLOUD
# ==============================================================================
# Este script desativa serviços para evitar custos após a demonstração.
#
# Uso:
# chmod +x shutdown.sh
# ./shutdown.sh
# ==============================================================================

set -e

echo "═══════════════════════════════════════════════════"
echo "      ENCERRANDO SERVIÇOS NO GOOGLE CLOUD"
echo "═══════════════════════════════════════════════════"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

PROJECT_ID="sis-gerenciamento-de-feedbacks"
REGION="us-central1"
SERVICE_NAME="feedback-backend"

echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá DESATIVAR recursos no projeto${NC}"
echo "Projeto: ${PROJECT_ID}"
echo ""
read -p "Digite 'SIM' para confirmar: " CONFIRM

if [ "$CONFIRM" != "SIM" ]; then
    echo "Operação cancelada."
    exit 0
fi

gcloud config set project ${PROJECT_ID}

echo -e "\n${RED}Iniciando encerramento...${NC}"

# ==============================================================================
# 1) Cloud Run
# ==============================================================================
echo -e "\n${YELLOW}[1/5] Removendo Cloud Run...${NC}"

if gcloud run services describe ${SERVICE_NAME} --region=${REGION} >/dev/null 2>&1 ; then
  gcloud run services delete ${SERVICE_NAME} --region=${REGION} --quiet
  echo -e "${GREEN}✓ Cloud Run removido${NC}"
else
  echo "Cloud Run já não existia"
fi

# ==============================================================================
# 2) Cloud Functions
# ==============================================================================
echo -e "\n${YELLOW}[2/5] Removendo Cloud Functions...${NC}"

FUNCS=("notifyadmin" "generatereport" "reporthttp")

for FN in "${FUNCS[@]}"; do
  if gcloud functions describe $FN --region=${REGION} >/dev/null 2>&1 ; then
    gcloud functions delete $FN --region=${REGION} --quiet
    echo "✓ $FN removida"
  else
    echo "$FN já não existia"
  fi
done

echo -e "${GREEN}✓ Cloud Functions processadas${NC}"

# ==============================================================================
# 3) Cloud Scheduler
# ==============================================================================
echo -e "\n${YELLOW}[3/5] Removendo Cloud Scheduler Job...${NC}"

if gcloud scheduler jobs describe weekly-report-job >/dev/null 2>&1 ; then
  gcloud scheduler jobs delete weekly-report-job --quiet
  echo -e "${GREEN}✓ Scheduler removido${NC}"
else
  echo "Scheduler já não existia"
fi

# ==============================================================================
# 4) Pub/Sub
# ==============================================================================
echo -e "\n${YELLOW}[4/5] Removendo Pub/Sub Topic...${NC}"

if gcloud pubsub topics describe weekly-report >/dev/null 2>&1 ; then
  gcloud pubsub topics delete weekly-report --quiet
  echo -e "${GREEN}✓ Pub/Sub removido${NC}"
else
  echo "Topic já não existia"
fi

# ==============================================================================
# 5) Cloud SQL (Somente aviso)
# ==============================================================================
echo -e "\n${YELLOW}[5/5] Cloud SQL${NC}"
echo "⚠️  Não removido automaticamente."
echo "Se quiser remover (perda TOTAL de dados):"
echo "  gcloud sql instances delete feedbackdb --quiet"
echo ""
echo "Se quiser apenas parar:"
echo "  gcloud sql instances patch feedbackdb --activation-policy=NEVER"

# ==============================================================================
# FINAL
# ==============================================================================
echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}      ✓ ENCERRAMENTO CONCLUÍDO COM SUCESSO${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Serviços Encerrados:${NC}"
echo "  ✓ Cloud Run removido"
echo "  ✓ Cloud Functions removidas"
echo "  ✓ Cloud Scheduler removido"
echo "  ✓ Pub/Sub removido"
echo "  ⚠️ Cloud SQL permanece ativo"

echo -e "\n${YELLOW}Verifique custos:${NC}"
echo "https://console.cloud.google.com/billing"
echo ""
