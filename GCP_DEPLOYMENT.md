# ☁️ Deploy Oficial - Google Cloud Platform (GCP)

Este guia descreve o **deploy completo e oficial do Sistema de Gerenciamento de Feedbacks no Google Cloud Platform**, cobrindo API principal + duas Cloud Functions + agendamento semanal.

---

## 🏗️ Arquitetura GCP

```
┌─────────────────────────────────────────────────────┐
│              GOOGLE CLOUD PLATFORM                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │ Cloud Run - feedback-backend                 │   │
│  │ Java 17 / Spring Boot                        │   │
│  │ Stateless / JWT Auth                         │   │
│  └────────┬─────────────────────────────────────┘   │
│           │                                         │
│           ├─► Cloud Functions (HTTP Trigger)        │
│           │    notifyadmin                          │
│           │    generatereport                       │
│           │    reporthttp (teste manual)            │
│           │                                         │
│           ├─► Cloud Functions (Pub/Sub Trigger)     │
│           │    generateWeeklyReport                 │
│           │                                         │
│           ├─► Cloud Scheduler + Pub/Sub             │
│           │ Executa relatório semanal               │
│           │                                         │
│           └─► Cloud Logging + Cloud Monitoring      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Pré-requisitos

1️⃣ Conta no Google Cloud  
2️⃣ Projeto criado e ativo  
3️⃣ Billing habilitado  
4️⃣ SDK instalado  

```bash
https://cloud.google.com/sdk/docs/install
```

Login:
```bash
gcloud auth login
gcloud config set project sis-gerenciamento-de-feedbacks
```

---

# 🚀 DEPLOY BACKEND – CLOUD RUN

### 1️⃣ Build do projeto

```bash
./mvnw clean package -DskipTests
```

O JAR gerado ficará em:
```
target/feedback-system-cloud-1.0.0.jar
```

---

### 2️⃣ Criar imagem Docker e enviar para Artifact Registry

Criar repositório (apenas 1 vez):

```bash
gcloud artifacts repositories create feedback-repo \
    --repository-format=docker \
    --location=us-central1
```

Autenticar:
```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

Build e push:

```bash
docker build -t us-central1-docker.pkg.dev/sis-gerenciamento-de-feedbacks/feedback-repo/backend .

docker push us-central1-docker.pkg.dev/sis-gerenciamento-de-feedbacks/feedback-repo/backend
```

---

### 3️⃣ Deploy no Cloud Run

```bash
gcloud run deploy feedback-backend \
 --image us-central1-docker.pkg.dev/sis-gerenciamento-de-feedbacks/feedback-repo/backend \
 --platform managed \
 --region us-central1 \
 --allow-unauthenticated
```

### Variáveis importantes

➡️ Configure no Cloud Run:
```
NOTIFICATION_FUNCTION_URL = https://notifyadmin-xxxx.a.run.app
jwt.secret = sua-chave-secreta-jwt-super-segura-256-bits-minimo
jwt.expiration = 86400000
```

---

# 🔔 Deploy Cloud Function – notifyadmin

```bash
cd cloud-functions/notification-function

gcloud functions deploy notifyadmin \
 --gen2 \
 --runtime=nodejs20 \
 --region=us-central1 \
 --trigger-http \
 --entry-point=notifyUrgentFeedback \
 --allow-unauthenticated
```

---

# 📊 Deploy Cloud Function – relatório manual (HTTP)

```bash
cd cloud-functions/report-function

gcloud functions deploy reporthttp \
 --gen2 \
 --runtime=nodejs20 \
 --region=us-central1 \
 --trigger-http \
 --entry-point=generateWeeklyReportHttp \
 --allow-unauthenticated
```

Configure variáveis:

```
API_URL=https://feedback-backend-xxxx.us-central1.run.app
ADMIN_EMAIL=admin@feedback.com
ADMIN_PASSWORD=admin123
```

---

# ⏰ Deploy Cloud Function – relatório semanal automático

### 1️⃣ Criar tópico Pub/Sub

```bash
gcloud pubsub topics create weekly-report
```

---

### 2️⃣ Deploy função agendada

```bash
gcloud functions deploy generatereport \
 --gen2 \
 --runtime=nodejs20 \
 --region=us-central1 \
 --trigger-topic=weekly-report \
 --entry-point=generateWeeklyReport
```

---

### 3️⃣ Criar agendamento Cloud Scheduler

Executa toda **segunda às 08:00**:

```bash
gcloud scheduler jobs create pubsub weekly-report-job \
 --schedule="0 8 * * 1" \
 --topic=weekly-report \
 --message-body="generate" \
 --time-zone="America/Sao_Paulo" \
 --location=us-central1
```

---

# 📡 URLs Finais

```
BACKEND_URL = https://feedback-backend-xxxx.run.app
NOTIFY_URL = https://notifyadmin-xxxx.a.run.app
REPORT_URL = https://generatereport-xxxx.a.run.app
WEEKLY_REPORT = Trigger via Cloud Scheduler + Pub/Sub
MANUAL_REPORT_URL = https://reporthttp-xxxx.a.run.app
```

---

# 📊 Monitoramento

### Ver logs Cloud Run

```bash
gcloud logs read \
  'resource.type="cloud_run_revision" AND resource.labels.service_name="feedback-backend"'
```

### Ver logs Cloud Functions

```bash
gcloud functions logs read notifyadmin --region us-central1
gcloud functions logs read generatereport --region us-central1
gcloud functions logs read reporthttp --region us-central1
```

Ou via Console:
> Cloud Run → Logs  
> Cloud Functions → Logs  

---

# 💰 Custos GCP

| Serviço | Custo |
|--------|------|
| Cloud Run | quase zero (free tier) |
| Cloud Functions | 2M execuções grátis |
| Pub/Sub | 10GB grátis |
| Scheduler | ~$0.10/mês |
| **TOTAL** | ~ **$18/mês** médio |

---

# 🛑 Encerrar serviços

```bash
gcloud run services delete feedback-backend

gcloud functions delete notifyadmin
gcloud functions delete generatereport
gcloud functions delete reporthttp

gcloud scheduler jobs delete weekly-report-job
gcloud pubsub topics delete weekly-report
```

---

# ⚔️ Azure x Google Cloud — Por que GCP?

| Aspecto | Azure | GCP |
|--------|-------|------|
| Backend Hosting | App Service | Cloud Run |
| Serverless | Azure Functions | Cloud Functions |
| Scheduler | Timer Trigger | Cloud Scheduler |
| Mensageria | Service Bus | Pub/Sub |
| Custo | mais caro | **mais barato** |
| Free Tier | 12 meses | Permanente |
| Simplicidade | boa | **excelente** |
| Logs | App Insights | Cloud Logging |
| Melhor para | Ambientes Microsoft | **Workloads Cloud Nativas** |

📌 **Motivo da escolha:**  
GCP oferece **menor custo, melhor simplicidade e funcionamento perfeito para workloads stateless com Cloud Run + Functions + Pub/Sub.**

---

# ✅ Checklist Deploy GCP

- [x] Cloud Run publicado
- [x] notifyadmin publicado
- [x] generateReport publicado
- [x] generateWeeklyReport publicado
- [x] Scheduler configurado
- [x] Logs validados
- [x] JWT funcionando
- [x] Testes executados

---

# 🆘 Troubleshooting

### 403 Forbidden
✔️ Token inválido  
✔️ jwt.secret diferente no Cloud Run  
✔️ Cabeçalho `Authorization: Bearer <token>` ausente  

---

### Função não dispara
✔️ Scheduler configurado  
✔️ Pub/Sub existente  
✔️ Função vinculada ao tópico correto  

---

### Timeout GCP
✔️ Backend rodando  
✔️ URL correta  
✔️ Autenticação funcionando  

---

# 📖 Referências
- https://cloud.run
- https://cloud.google.com/functions
- https://cloud.google.com/scheduler
- https://cloud.google.com/logging

---

🎯 **Deploy GCP concluído com sucesso!**