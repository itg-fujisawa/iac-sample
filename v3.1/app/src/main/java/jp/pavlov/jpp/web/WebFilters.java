package jp.pavlov.jpp.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.web.filter.OncePerRequestFilter;

@Configuration
public class WebFilters {

    /**
     * Cloud Logging のトレース相関。LB が付与する traceparent / X-Cloud-Trace-Context から
     * trace ID を取り出し、構造化ログの logging.googleapis.com/trace に出す。
     */
    @Bean
    @Order(Ordered.HIGHEST_PRECEDENCE)
    OncePerRequestFilter traceFilter(@Value("${app.project-id:}") String projectId) {
        return new OncePerRequestFilter() {
            @Override
            protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
                    throws ServletException, IOException {
                String traceId = null;
                String spanId = null;
                String tp = req.getHeader("traceparent"); // 00-<trace32>-<span16>-<flags>
                if (tp != null) {
                    String[] p = tp.split("-");
                    if (p.length >= 3) {
                        traceId = p[1];
                        spanId = p[2];
                    }
                } else {
                    String xc = req.getHeader("X-Cloud-Trace-Context"); // <trace>/<span>;o=1
                    if (xc != null && !xc.isBlank()) {
                        String[] p = xc.split("[/;]");
                        traceId = p[0];
                        if (p.length > 1) {
                            spanId = p[1];
                        }
                    }
                }
                try {
                    if (traceId != null && !projectId.isBlank()) {
                        MDC.put("trace", "projects/" + projectId + "/traces/" + traceId);
                        if (spanId != null) {
                            MDC.put("spanId", spanId);
                        }
                    }
                    chain.doFilter(req, res);
                } finally {
                    MDC.remove("trace");
                    MDC.remove("spanId");
                }
            }
        };
    }

    /** API 応答を CDN・ブラウザにキャッシュさせない（個人・権限別データの共有キャッシュ防止）。 */
    @Bean
    OncePerRequestFilter noStoreFilter() {
        return new OncePerRequestFilter() {
            @Override
            protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
                    throws ServletException, IOException {
                if (req.getRequestURI().startsWith("/api/")) {
                    res.setHeader("Cache-Control", "no-store");
                }
                chain.doFilter(req, res);
            }
        };
    }
}
