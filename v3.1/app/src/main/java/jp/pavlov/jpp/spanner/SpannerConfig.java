package jp.pavlov.jpp.spanner;

import com.google.cloud.spanner.DatabaseClient;
import com.google.cloud.spanner.DatabaseId;
import com.google.cloud.spanner.ResultSet;
import com.google.cloud.spanner.Spanner;
import com.google.cloud.spanner.SpannerOptions;
import com.google.cloud.spanner.Statement;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * SPANNER_DATABASE（projects/../instances/../databases/..）が設定されたときだけ有効。
 * 認証は Cloud Run の実行SA（ADC）。キーファイルは使わない。
 */
@Configuration
@ConditionalOnExpression("!'${app.spanner.database:}'.isBlank()")
public class SpannerConfig {

    @Bean(destroyMethod = "close")
    Spanner spanner() {
        return SpannerOptions.newBuilder().build().getService();
    }

    @Bean
    DatabaseClient spannerDatabaseClient(Spanner spanner, @Value("${app.spanner.database}") String database) {
        return spanner.getDatabaseClient(DatabaseId.of(database));
    }

    /** readiness グループの "spanner"（application-spanner.yaml で組み込む）。 */
    @Bean
    HealthIndicator spannerHealthIndicator(DatabaseClient client) {
        return () -> {
            try (ResultSet rs = client.singleUse().executeQuery(Statement.of("SELECT 1"))) {
                rs.next();
                return Health.up().build();
            } catch (RuntimeException e) {
                return Health.down().withDetail("error", e.getClass().getSimpleName()).build();
            }
        };
    }
}
