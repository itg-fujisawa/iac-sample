package jp.pavlov.jpp.web;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * URL map の path_rule（/p/* 特実、/d/* 意匠、/t/* 商標、/s/* 審判）で振り分けられた
 * リクエストの受け口（雛形）。業務機能は各サービスの実装で置き換える。
 */
@RestController
public class ServiceRouteController {

    private final String service;

    public ServiceRouteController(@Value("${app.service}") String service) {
        this.service = service;
    }

    @GetMapping({"/p/**", "/d/**", "/t/**", "/s/**"})
    public Map<String, String> route(HttpServletRequest request) {
        return Map.of("service", service, "path", request.getRequestURI());
    }
}
