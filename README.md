# 📚 Sistema de Feedbacks — Portal Principal de Documentação

Bem-vindo ao portal oficial de documentação do **Sistema de Gerenciamento de Feedbacks Acadêmicos**.  
Aqui você acessa rapidamente tudo o que precisa para **executar, entender, testar, apresentar e monitorar** o sistema.

---

## 🚀 Acesso Rápido (clique para abrir)

### 📄 Documentações Principais
- 👉 **[README (Portal Principal)](README.md)**
- 👉 **[QUICKSTART — Guia Rápido](QUICKSTART.md)**
- 👉 **[RELATÓRIO TÉCNICO](RELATORIO_TECNICO_DETALHADO.md)**
- 👉 **[PROJETO COMPLETO](PROJETO_COMPLETO.txt)**

---

## ☁️ Google Cloud — Deploy & Infraestrutura

- 🌩 **[GCP_DEPLOYMENT.md — Deploy no Google Cloud](GCP_DEPLOYMENT.md)**
- 🏗 **Arquivos de Deploy**
  - **[deploy.sh](deploy.sh)** — deploy automatizado completo
  - **[shutdown.sh](shutdown.sh)** — encerra recursos para evitar custos
  - **[cloudbuild.yaml](cloudbuild.yaml)** — CI/CD unificado

---

## 🌐 API — Uso e Testes

- 📡 **[API_EXAMPLES.md — Exemplos de requisições da API](api_examples.md)**
- 🧪 **Postman Collection**
  - **[FeedbackAPI.postman_collection.json](FeedbackAPI.postman_collection.json)**

---

## 🔧 Código Fonte

- 📦 Backend:
  - Java + Spring Boot
  - JWT Authentication
  - JPA + H2 (In-Memory no GCP — zero custo)

- ⚙️ Cloud Functions
  - notification-function
  - report-function
  - reporthttp (manual test)

---

## 👀 Monitoramento
- Logs no Cloud Run
- Logs nas Cloud Functions
- Cloud Scheduler para relatórios semanais
- Pub/Sub para disparo automático

---

## ✅ Status Final
✔️ Funciona localmente  
✔️ Funciona 100% no GCP  
✔️ Integração Backend + Cloud Functions OK  
✔️ JWT + Segurança OK  

---

## 📄 Licença

Este projeto é de código aberto para fins educacionais.

---