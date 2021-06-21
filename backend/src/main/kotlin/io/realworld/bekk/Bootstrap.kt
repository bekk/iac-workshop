package io.realworld.bekk

import io.realworld.model.Article
import io.realworld.model.User
import io.realworld.service.UserService
import io.realworld.repository.UserRepository
import io.realworld.repository.ArticleRepository
import org.mindrot.jbcrypt.BCrypt
import org.slf4j.LoggerFactory
import org.springframework.boot.context.event.ApplicationReadyEvent
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Component
import java.time.OffsetDateTime

@Component
class Bootstrap(
    private val userService: UserService,
    private val userRepository: UserRepository,
    private val articleRepository: ArticleRepository
) {
    private val BEKK_USERNAME = "rett-i-prod"
    private val BEKK_EMAIL = "rett-i-prod@bekk.no"
    private val BEKK_PASSWORD = BCrypt.hashpw("hello-world", BCrypt.gensalt())
    
    @EventListener(ApplicationReadyEvent::class)
    fun initDatabase() {
        var user: User? = null

        if (!userRepository.existsByEmail(BEKK_EMAIL)) {
            var bekkUser = User(email = BEKK_EMAIL, username = BEKK_USERNAME, password = BEKK_PASSWORD)
            bekkUser.token = userService.newToken(bekkUser)
            bekkUser = userRepository.save(bekkUser)
            user = bekkUser
            log.info("Created sample user with email {}", BEKK_EMAIL)
        }

        user?.let { u: User ->
            val article = Article(
                title = "Hello world",
                slug = "hello-world",
                author = u,
                description = "Backend fungerer",
                body = "Alt fungerer som forventet",
                createdAt = OffsetDateTime.now()
            )
            articleRepository.save(article)
            log.info("Created sample article")
        }
    }

    companion object {
        private val log = LoggerFactory.getLogger(Bootstrap::class.java)
    }
}
