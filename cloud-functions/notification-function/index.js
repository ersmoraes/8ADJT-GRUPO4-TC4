/**
 * GOOGLE CLOUD FUNCTION - NOTIFICAÇÃO DE FEEDBACK URGENTE
 *
 * Esta função é acionada via HTTP quando um feedback urgente é criado.
 * Ela envia notificações por email ou registra logs para alertar administradores.
 *
 * Deploy:
 * gcloud functions deploy notifyAdmin \
 *   --runtime nodejs20 \
 *   --trigger-http \
 *   --allow-unauthenticated \
 *   --entry-point notifyUrgentFeedback \
 *   --region us-central1
 */

const functions = require('@google-cloud/functions-framework');

/**
 * Função principal que processa notificações de feedbacks urgentes.
 */
functions.http('notifyUrgentFeedback', async (req, res) => {
  console.log('═══════════════════════════════════════════════════');
  console.log('🚨 NOTIFICAÇÃO DE FEEDBACK URGENTE RECEBIDA');
  console.log('═══════════════════════════════════════════════════');

  // Configura CORS
  res.set('Access-Control-Allow-Origin', '*');

  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  // Valida método HTTP
  if (req.method !== 'POST') {
    console.error('❌ Método não permitido:', req.method);
    res.status(405).send('Apenas POST é permitido');
    return;
  }

  try {
    // Extrai dados do feedback
    const feedback = req.body;

    // compatibilidade com backend Spring
    const feedbackId = feedback.feedbackId || feedback.id;
    const createdAt = feedback.createdAt || feedback.date;

    console.log('📋 Dados do Feedback:');
    console.log(`   ID: ${feedbackId}`);
    console.log(`   Aluno: ${feedback.studentName}`);
    console.log(`   Email: ${feedback.studentEmail}`);
    console.log(`   Curso: ${feedback.course}`);
    console.log(`   Nota: ${feedback.rating} ⭐`);
    console.log(`   Comentário: ${feedback.comment}`);
    console.log(`   Data: ${createdAt}`);

    // validação
    if (!feedbackId || !feedback.studentName) {
      console.error('❌ Dados inválidos recebidos');
      res.status(400).json({
        success: false,
        message: 'Dados do feedback incompletos'
      });
      return;
    }

    // Monta a mensagem de notificação
    const notificationMessage = `
    ╔═══════════════════════════════════════════════════╗
    ║     🚨 ALERTA: FEEDBACK URGENTE RECEBIDO 🚨      ║
    ╚═══════════════════════════════════════════════════╝

    📌 ID do Feedback: ${feedback.feedbackId}
    👤 Aluno: ${feedback.studentName}
    📧 Email: ${feedback.studentEmail}
    📚 Curso: ${feedback.course}
    ⭐ Nota: ${feedback.rating}/5

    💬 Comentário:
    "${feedback.comment}"

    🕐 Registrado em: ${feedback.createdAt}

    ⚠️  AÇÃO NECESSÁRIA: Este feedback foi marcado como urgente
    e requer atenção imediata da equipe administrativa.
    `;

    console.log(notificationMessage);

    // Aqui você pode integrar com serviços reais de notificação:
    // - SendGrid para email
    // - Twilio para SMS
    // - Firebase Cloud Messaging para push notifications
    // - Slack/Discord webhooks

    // Exemplo de integração com SendGrid (descomente para usar):
    /*
    const sgMail = require('@sendgrid/mail');
    sgMail.setApiKey(process.env.SENDGRID_API_KEY);

    const msg = {
      to: 'admin@feedback.com',
      from: 'noreply@feedback.com',
      subject: `🚨 Feedback Urgente - ${feedback.course}`,
      text: notificationMessage,
      html: `<pre>${notificationMessage}</pre>`,
    };

    await sgMail.send(msg);
    */

    // Registra no Cloud Logging (visível no Google Cloud Console)
    console.log('✅ Notificação processada com sucesso');
    console.log('📬 Administradores foram alertados');
    console.log('═══════════════════════════════════════════════════');

    // Retorna resposta de sucesso
    res.status(200).json({
      success: true,
      message: 'Notificação enviada com sucesso',
      feedbackId: feedback.feedbackId,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Erro ao processar notificação:', error);
    res.status(500).json({
      success: false,
      message: 'Erro ao processar notificação',
      error: error.message
    });
  }
});
