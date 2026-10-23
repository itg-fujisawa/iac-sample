package jp.pavlov.jpp.job;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Cloud Run Jobs 用。APP_JOB_NAME で処理を選ぶ。
 * 例外を投げるとタスク失敗（非0終了）となり、Cloud Run Jobs の max_retries で再試行される。
 * 再試行に備え、処理は冪等に実装すること。
 */
@Component
@ConditionalOnProperty(prefix = "app.job", name = "name")
public class JobRunner implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(JobRunner.class);

    private final String jobName;
    private final ObjectProvider<JdbcTemplate> jdbc;

    public JobRunner(@Value("${app.job.name}") String jobName, ObjectProvider<JdbcTemplate> jdbc) {
        this.jobName = jobName;
        this.jdbc = jdbc;
    }

    @Override
    public void run(ApplicationArguments args) {
        String taskIndex = System.getenv().getOrDefault("CLOUD_RUN_TASK_INDEX", "0");
        String taskCount = System.getenv().getOrDefault("CLOUD_RUN_TASK_COUNT", "1");
        log.info("job start name={} task={}/{}", jobName, taskIndex, taskCount);

        switch (jobName) {
            case "daily-load" -> dailyLoad(Integer.parseInt(taskIndex), Integer.parseInt(taskCount));
            default -> throw new IllegalArgumentException("unknown job: " + jobName);
        }
        log.info("job end name={} task={}", jobName, taskIndex);
    }

    /** 雛形：DB 接続確認のみ。業務処理（公報の取込み等）は task 番号で範囲を分割して実装する。 */
    private void dailyLoad(int taskIndex, int taskCount) {
        JdbcTemplate t = jdbc.getIfAvailable();
        if (t == null) {
            throw new IllegalStateException("DataSource is not configured");
        }
        Integer one = t.queryForObject("SELECT 1", Integer.class);
        log.info("db check result={} shard={}/{}", one, taskIndex, taskCount);
    }
}
