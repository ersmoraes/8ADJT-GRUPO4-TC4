# 🎓 Sistema de Gerenciamento de Feedbacks - Cloud Serverless

Sistema completo de backend para gerenciamento de feedbacks de alunos, com arquitetura serverless implantada em **Google Cloud Platform**, incluindo notificações automáticas e relatórios semanais.

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Tecnologias](#-tecnologias)
- [Funcionalidades](#-funcionalidades)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação e Execução Local](#-instalação-e-execução-local)
- [Deploy no Google Cloud](#-deploy-no-google-cloud)
- [API Endpoints](#-api-endpoints)
- [Testes com Exemplos](#-testes-com-exemplos)
- [Monitoramento](#-monitoramento)
- [Encerramento dos Serviços](#-encerramento-dos-serviços)

---

## 🎯 Visão Geral

Este sistema permite:

- **Alunos** registrarem feedbacks sobre cursos com nota (1-5) e comentários
- **Administradores** consultarem todos os feedbacks e gerarem relatórios
- **Notificação automática** quando um feedback é marcado como urgente
- **Relatório semanal automático** gerado toda segunda-feira às 08:00
- **Segurança por perfil** (STUDENT vs ADMIN) com autenticação JWT
- **Implantação 100% serverless** no Google Cloud

---

## 🏗️ Arquitetura

### Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                    GOOGLE CLOUD PLATFORM                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐      ┌─────────────────────────┐    │
│  │   App Engine     │◄─────┤   Cloud SQL (PostgreSQL)│    │
│  │  (Spring Boot)   │      └─────────────────────────┘    │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ├──► Cloud Function 1: Notificação Urgente       │
│           │    Trigger: HTTP POST                          │
│           │    Ação: Envia alerta aos admins               │
│           │                                                 │
│           └──► Cloud Function 2: Relatório Semanal         │
│                Trigger: Cloud Scheduler (segunda 08:00)    │
│                Ação: Gera e envia relatório                │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Cloud Monitoring + Cloud Logging                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Modelo de Cloud: **PaaS (Platform as a Service)**

**Justificativa Técnica:**

1. **Redução de Complexidade**: Não é necessário gerenciar servidores, patches ou infraestrutura
2. **Escalabilidade Automática**: App Engine e Cloud Functions escalam automaticamente conforme demanda
3. **Custo Otimizado**: Paga-se apenas pelo uso (modelo pay-as-you-go)
4. **Alta Disponibilidade**: SLA de 99.95% garantido pelo Google Cloud
5. **Foco no Código**: Equipe de desenvolvimento foca em features, não em infraestrutura

---

## 💻 Tecnologias

### Backend API
- **Java 17**
- **Spring Boot 3.2**
- **Spring Security** (JWT Authentication)
- **Spring Data JPA** (Hibernate)
- **PostgreSQL** (produção) / **H2** (desenvolvimento)

### Cloud Functions
- **Node.js 20**
- **Google Cloud Functions Framework**

### Cloud Services
- **Google App Engine** (hospedagem da API)
- **Google Cloud SQL** (banco de dados PostgreSQL)
- **Google Cloud Functions** (funções serverless)
- **Google Cloud Scheduler** (agendamento de tarefas)
- **Google Cloud Pub/Sub** (mensageria)
- **Google Cloud Monitoring** (observabilidade)

---

## ✨ Funcionalidades

### 👨‍🎓 Para Alunos (ROLE_STUDENT)
- ✅ Criar feedback com nota e comentário
- ✅ Marcar feedback como urgente
- ✅ Consultar próprios feedbacks

### 👨‍💼 Para Administradores (ROLE_ADMIN)
- ✅ Visualizar todos os feedbacks
- ✅ Filtrar feedbacks urgentes
- ✅ Gerar relatórios manuais
- ✅ Acessar estatísticas gerais

### 🤖 Automações
- ✅ Notificação instantânea de feedbacks urgentes
- ✅ Relatório semanal automático (segundas às 08:00)
- ✅ Monitoramento de saúde da aplicação

---

## 📦 Pré-requisitos

### Para Desenvolvimento Local
- **Java 17+** ([Download](https://adoptium.net/))
- **Maven 3.8+** ([Download](https://maven.apache.org/download.cgi))
- **Node.js 18+** ([Download](https://nodejs.org/))
- **Git** ([Download](https://git-scm.com/))

### Para Deploy no Google Cloud
- **Conta Google Cloud** (free tier disponível)
- **Google Cloud SDK** ([Download](https://cloud.google.com/sdk/docs/install))
- **Billing habilitado** no projeto GCP

---

## 🚀 Instalação e Execução Local

### 1. Clone o repositório

```bash
git clone https://github.com/ersmoraes/8ADJT-GRUPO4-TC4.git
cd 8ADJT-GRUPO4-TC4
```

### 2. Execute a API Spring Boot

```bash
# Compile e execute
./mvnw spring-boot:run

# Ou usando Maven direto
mvn clean spring-boot:run
```

A API estará disponível em: `http://localhost:8080`

### 3. Execute as Cloud Functions localmente (opcional)

**Função de Notificação:**
```bash
cd cloud-functions/notification-function
npm install
npm start
# Disponível em http://localhost:8081
```

**Função de Relatório:**
```bash
cd cloud-functions/report-function
npm install
npm start
# Disponível em http://localhost:8082
```

### 4. Acesse o H2 Console (desenvolvimento)

URL: `http://localhost:8080/h2-console`

- **JDBC URL**: `jdbc:h2:mem:feedbackdb`
- **Username**: `sa`
- **Password**: (deixe em branco)

---

## ☁️ Deploy no Google Cloud

### Passo 1: Configurar Google Cloud

```bash
# Instalar Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Fazer login
gcloud auth login

# Criar projeto
gcloud projects create feedback-system-2024 --name="Feedback System"

# Configurar projeto
gcloud config set project feedback-system-2024

# Habilitar APIs necessárias
gcloud services enable \
  appengine.googleapis.com \
  sqladmin.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudscheduler.googleapis.com \
  cloudbuild.googleapis.com

# Habilitar billing
# https://console.cloud.google.com/billing
```

### Passo 2: Configurar Variáveis

Edite o arquivo `app.yaml` e `deploy.sh` com seus valores:

```yaml
# app.yaml
env_variables:
  DB_USER: "seu-usuario"
  DB_PASSWORD: "sua-senha-segura"
  INSTANCE_CONNECTION_NAME: "seu-projeto:us-central1:feedbackdb"
```

### Passo 3: Deploy Automatizado

```bash
# Dar permissão de execução
chmod +x deploy.sh

# Executar deploy completo
./deploy.sh
```

O script irá:
1. ✅ Criar instância Cloud SQL (PostgreSQL)
2. ✅ Fazer build da aplicação Spring Boot
3. ✅ Deploy no App Engine
4. ✅ Deploy das Cloud Functions
5. ✅ Configurar Cloud Scheduler

### Passo 4: Verificar Deploy

```bash
# Ver logs da aplicação
gcloud app logs tail -s default

# Ver status do App Engine
gcloud app describe

# Listar Cloud Functions
gcloud functions list
```

---

## 📡 API Endpoints

### Autenticação

#### `POST /api/auth/login`
Realiza login e retorna token JWT.

**Request:**
```json
{
  "email": "admin@feedback.com",
  "password": "admin123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer",
  "email": "admin@feedback.com",
  "name": "Administrador do Sistema",
  "role": "ROLE_ADMIN"
}
```

---

### Endpoints de Aluno (ROLE_STUDENT)

#### `POST /api/feedbacks`
Criar novo feedback.

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "studentName": "Maria Silva",
  "studentEmail": "maria.silva@aluno.com",
  "course": "Engenharia de Software",
  "rating": 5,
  "comment": "Excelente curso! Conteúdo muito bem estruturado.",
  "urgent": false
}
```

**Response:** `201 Created`
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "studentName": "Maria Silva",
  "studentEmail": "maria.silva@aluno.com",
  "course": "Engenharia de Software",
  "rating": 5,
  "comment": "Excelente curso!",
  "urgent": false,
  "createdAt": "2024-01-15T10:30:00"
}
```

#### `GET /api/feedbacks/me`
Listar feedbacks do aluno logado.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:** `200 OK`
```json
[
  {
    "id": "...",
    "studentName": "Maria Silva",
    "course": "Engenharia de Software",
    "rating": 5,
    "comment": "...",
    "urgent": false,
    "createdAt": "2024-01-15T10:30:00"
  }
]
```

---

### Endpoints de Admin (ROLE_ADMIN)

#### `GET /api/admin/feedbacks`
Listar todos os feedbacks.

**Query Parameters:**
- `lastWeek=true` (opcional): retorna apenas feedbacks da última semana

**Headers:**
```
Authorization: Bearer {token_admin}
```

**Response:** `200 OK`

#### `GET /api/admin/feedbacks/urgent`
Listar apenas feedbacks urgentes.

#### `POST /api/admin/report/weekly`
Gerar relatório semanal manualmente.

**Response:**
```json
{
  "reportGeneratedAt": "2024-01-15T10:00:00",
  "periodStart": "2024-01-08T10:00:00",
  "periodEnd": "2024-01-15T10:00:00",
  "totalFeedbacks": 25,
  "urgentFeedbacks": 3,
  "averageRating": "4.20",
  "ratingDistribution": {
    "5": 10,
    "4": 8,
    "3": 4,
    "2": 2,
    "1": 1
  },
  "topCourses": {
    "Engenharia de Software": 10,
    "Ciência de Dados": 8,
    "DevOps": 7
  },
  "criticalFeedbacks": 3
}
```

#### `GET /api/admin/stats`
Estatísticas gerais.

---

## 🧪 Testes com Exemplos

### 1. Login como Aluno

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "maria.silva@aluno.com",
    "password": "maria123"
  }'
```

### 2. Criar Feedback Normal

```bash
curl -X POST http://localhost:8080/api/feedbacks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN" \
  -d '{
    "studentName": "Maria Silva",
    "studentEmail": "maria.silva@aluno.com",
    "course": "Engenharia de Software",
    "rating": 5,
    "comment": "Curso excelente, aprendi muito!",
    "urgent": false
  }'
```

### 3. Criar Feedback Urgente (dispara notificação)

```bash
curl -X POST http://localhost:8080/api/feedbacks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN" \
  -d '{
    "studentName": "João Santos",
    "studentEmail": "joao.santos@aluno.com",
    "course": "Banco de Dados",
    "rating": 1,
    "comment": "Sistema fora do ar há 2 dias!",
    "urgent": true
  }'
```

### 4. Login como Admin

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@feedback.com",
    "password": "admin123"
  }'
```

### 5. Gerar Relatório (Admin)

```bash
curl -X POST http://localhost:8080/api/admin/report/weekly \
  -H "Authorization: Bearer TOKEN_ADMIN"
```

---

## 📊 Monitoramento

### Google Cloud Monitoring

Acesse: [https://console.cloud.google.com/monitoring](https://console.cloud.google.com/monitoring)

**Métricas Monitoradas:**
- Taxa de requisições (requests/segundo)
- Latência média das APIs
- Erros HTTP (4xx, 5xx)
- Uso de CPU e memória
- Execuções das Cloud Functions

### Logs

```bash
# Logs da API (App Engine)
gcloud app logs tail -s default

# Logs da Cloud Function de Notificação
gcloud functions logs read notifyAdmin --region us-central1

# Logs da Cloud Function de Relatório
gcloud functions logs read generateReport --region us-central1
```

### Health Check

```bash
curl http://localhost:8080/actuator/health
```

**Response:**
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP"
    },
    "diskSpace": {
      "status": "UP"
    }
  }
}
```

---

## 🔒 Segurança

### Políticas Implementadas

1. **Autenticação JWT**: Todos os endpoints (exceto login) requerem token válido
2. **Autorização por Perfil**:
   - STUDENT: acesso apenas aos próprios dados
   - ADMIN: acesso total ao sistema
3. **Senha Criptografada**: BCrypt com salt automático
4. **HTTPS Obrigatório**: App Engine força TLS 1.2+
5. **Validação de Input**: Bean Validation em todos os DTOs
6. **Rate Limiting**: Configurável no App Engine

---

## 💰 Estimativa de Custos

### Google Cloud Free Tier

- **App Engine**: 28 horas/dia grátis (instância F1)
- **Cloud SQL**: 1 instância db-f1-micro grátis
- **Cloud Functions**: 2 milhões de invocações/mês grátis
- **Cloud Scheduler**: 3 jobs grátis

### Custo Mensal Estimado (após free tier)

- App Engine Standard: ~$5-10/mês (tráfego baixo)
- Cloud SQL (f1-micro): ~$7/mês
- Cloud Functions: ~$0.50/mês (baixo volume)
- **Total**: **$12-18/mês** (uso moderado)

### Otimização de Custos

1. Use `min_instances: 0` no App Engine (cold start aceitável)
2. Cloud SQL pode ser pausado em desenvolvimento
3. Logs podem ser filtrados para reduzir storage
4. Scaling automático ajusta recursos conforme demanda

---

## 🛑 Encerramento dos Serviços

**IMPORTANTE:** Execute após a apresentação para evitar custos!

```bash
# Dar permissão de execução
chmod +x shutdown.sh

# Executar encerramento
./shutdown.sh
```

O script irá:
1. ✅ Parar todas as versões do App Engine
2. ✅ Deletar Cloud Functions
3. ✅ Deletar Cloud Scheduler jobs
4. ✅ Deletar Pub/Sub topics
5. ⚠️ Cloud SQL requer ação manual (para segurança dos dados)

### Deletar Cloud SQL (DADOS SERÃO PERDIDOS!)

```bash
gcloud sql instances delete feedbackdb --quiet
```

### Ou apenas pausar (sem perder dados):

```bash
gcloud sql instances patch feedbackdb --activation-policy=NEVER
```

---

## 📚 Estrutura do Projeto

```
8ADJT-GRUPO4-TC4/
├── src/main/java/com/feedback/system/
│   ├── model/              # Entidades JPA
│   ├── repository/         # Repositórios Spring Data
│   ├── service/            # Lógica de negócio
│   ├── controller/         # REST Controllers
│   ├── security/           # JWT e autenticação
│   ├── dto/                # Data Transfer Objects
│   └── config/             # Configurações Spring
├── cloud-functions/
│   ├── notification-function/   # Cloud Function de notificação
│   └── report-function/         # Cloud Function de relatório
├── app.yaml                # Configuração App Engine
├── cloudbuild.yaml         # CI/CD automático
├── deploy.sh               # Script de deploy
├── shutdown.sh             # Script de encerramento
└── README.md               # Este arquivo
```

---

## 🤝 Credenciais de Teste

### Usuário Administrador
- **Email**: `admin@feedback.com`
- **Senha**: `admin123`
- **Perfil**: `ROLE_ADMIN`

### Usuário Aluno 1
- **Email**: `maria.silva@aluno.com`
- **Senha**: `maria123`
- **Perfil**: `ROLE_STUDENT`

### Usuário Aluno 2
- **Email**: `joao.santos@aluno.com`
- **Senha**: `joao123`
- **Perfil**: `ROLE_STUDENT`

---

## 📄 Licença

Este projeto é de código aberto para fins educacionais.

---

## 👨‍💻 Autor

Desenvolvido como projeto de demonstração de arquitetura serverless com Spring Boot e Google Cloud Platform.
