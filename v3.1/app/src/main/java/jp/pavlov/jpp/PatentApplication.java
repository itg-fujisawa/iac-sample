package jp.pavlov.jpp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

/**
 * Cloud Run サービスと Cloud Run Jobs で同じイメージを使う。
 * 環境変数 APP_JOB_NAME（= app.job.name）があればジョブとして実行し、終了コードを返して停止する。
 */
@SpringBootApplication
public class PatentApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext ctx = SpringApplication.run(PatentApplication.class, args);
        String job = ctx.getEnvironment().getProperty("app.job.name", "");
        if (!job.isBlank()) {
            System.exit(SpringApplication.exit(ctx));
        }
    }
}
