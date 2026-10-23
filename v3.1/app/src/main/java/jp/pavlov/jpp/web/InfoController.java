package jp.pavlov.jpp.web;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** 配備確認用（どの環境・サービス・版が応答したか）。機微情報は返さない。 */
@RestController
public class InfoController {

    private final String env;
    private final String service;
    private final String version;

    public InfoController(@Value("${app.env}") String env,
                          @Value("${app.service}") String service,
                          @Value("${app.version}") String version) {
        this.env = env;
        this.service = service;
        this.version = version;
    }

    @GetMapping("/api/info")
    public Map<String, String> info() {
        return Map.of("env", env, "service", service, "version", version);
    }
}
