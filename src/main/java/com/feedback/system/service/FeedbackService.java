package com.feedback.system.service;

import com.feedback.system.dto.FeedbackRequest;
import com.feedback.system.dto.FeedbackResponse;
import com.feedback.system.model.Feedback;
import com.feedback.system.repository.FeedbackRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Serviço de negócio para gerenciamento de feedbacks.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FeedbackService {

    private final FeedbackRepository feedbackRepository;
    private final NotificationService notificationService;

    /**
     * Cria um novo feedback.
     * Se for urgente, dispara uma notificação automática.
     */
    @Transactional
    public FeedbackResponse createFeedback(FeedbackRequest request) {
        log.info("Criando novo feedback para aluno: {}", request.getStudentEmail());

        Feedback feedback = new Feedback();
        feedback.setStudentName(request.getStudentName());
        feedback.setStudentEmail(request.getStudentEmail());
        feedback.setCourse(request.getCourse());
        feedback.setRating(request.getRating());
        feedback.setComment(request.getComment());
        feedback.setUrgent(request.isUrgent());

        Feedback savedFeedback = feedbackRepository.saveAndFlush(feedback);
        log.info("Feedback criado com sucesso. ID: {}", savedFeedback.getId());

        // Se for urgente, envia notificação
        if (savedFeedback.isUrgent()) {
            log.warn("Feedback urgente detectado! Enviando notificação...");
            notificationService.sendUrgentFeedbackNotification(savedFeedback);
        }

        return FeedbackResponse.fromEntity(savedFeedback);
    }

    /**
     * Busca todos os feedbacks.
     */
    public List<FeedbackResponse> getAllFeedbacks() {
        log.info("Buscando todos os feedbacks");
        return feedbackRepository.findAll()
                .stream()
                .map(FeedbackResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Busca feedbacks por email do aluno.
     */
    public List<FeedbackResponse> getFeedbacksByStudent(String email) {
        log.info("Buscando feedbacks do aluno: {}", email);
        return feedbackRepository.findByStudentEmailOrderByCreatedAtDesc(email)
                .stream()
                .map(FeedbackResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Busca um feedback por ID.
     */
    public FeedbackResponse getFeedbackById(String id) {
        log.info("Buscando feedback por ID: {}", id);
        Feedback feedback = feedbackRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Feedback não encontrado"));
        return FeedbackResponse.fromEntity(feedback);
    }

    /**
     * Busca feedbacks urgentes.
     */
    public List<FeedbackResponse> getUrgentFeedbacks() {
        log.info("Buscando feedbacks urgentes");
        return feedbackRepository.findByUrgentTrue()
                .stream()
                .map(FeedbackResponse::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Busca feedbacks da última semana.
     */
    public List<Feedback> getLastWeekFeedbacks() {
        LocalDateTime oneWeekAgo = LocalDateTime.now().minusWeeks(1);
        LocalDateTime now = LocalDateTime.now();
        log.info("Buscando feedbacks da última semana");
        return feedbackRepository.findByCreatedAtBetween(oneWeekAgo, now);
    }

    /**
     * Calcula a média geral de avaliações.
     */
    public Double calculateOverallAverageRating() {
        Double average = feedbackRepository.calculateOverallAverageRating();
        return average != null ? average : 0.0;
    }

    /**
     * Conta feedbacks urgentes.
     */
    public long countUrgentFeedbacks() {
        return feedbackRepository.countByUrgentTrue();
    }

    /**
     * Busca os feedbacks mais recentes.
     */
    public List<Feedback> getRecentFeedbacks() {
        return feedbackRepository.findTop10ByOrderByCreatedAtDesc();
    }
}
