package jp.pavlov.jpp;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("local")
class PatentApplicationTests {

    @Autowired
    TestRestTemplate http;

    @Test
    void healthzIsUp() {
        assertThat(http.getForEntity("/healthz", String.class).getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void readyzIsUpWithoutDbInLocalProfile() {
        assertThat(http.getForEntity("/readyz", String.class).getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void apiResponsesAreNotCacheable() {
        ResponseEntity<String> res = http.getForEntity("/api/info", String.class);
        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(res.getHeaders().getCacheControl()).isEqualTo("no-store");
    }

    @Test
    void searchWithoutSpannerReturns503NotEmptyResult() {
        assertThat(http.getForEntity("/api/search?q=test", String.class).getStatusCode())
                .isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
    }

    @Test
    void invalidPageSizeReturns400() {
        assertThat(http.getForEntity("/api/search?q=test&size=1000", String.class).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
