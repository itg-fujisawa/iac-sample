package jp.pavlov.jpp.logging;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.classic.spi.IThrowableProxy;
import ch.qos.logback.classic.spi.ThrowableProxyUtil;
import org.springframework.boot.json.JsonWriter;
import org.springframework.boot.logging.structured.StructuredLogFormatter;

/**
 * Cloud Logging 形式の JSON 1行ログ（Spring Boot 3.4+ の構造化ログ機能を使用）。
 * severity を Cloud Logging の重大度に合わせ、例外はスタックトレースを message に含めて
 * Error Reporting が検出できるようにする。trace は WebFilters が MDC に設定する。
 */
public class CloudLoggingFormatter implements StructuredLogFormatter<ILoggingEvent> {

    private final JsonWriter<ILoggingEvent> writer = JsonWriter.<ILoggingEvent>of((members) -> {
        members.add("severity", (event) -> severity(event.getLevel()));
        members.add("message", CloudLoggingFormatter::message);
        members.add("time", (event) -> event.getInstant().toString());
        members.add("logger", ILoggingEvent::getLoggerName);
        members.add("thread", ILoggingEvent::getThreadName);
        members.add("logging.googleapis.com/trace", (event) -> event.getMDCPropertyMap().get("trace")).whenNotNull();
        members.add("logging.googleapis.com/spanId", (event) -> event.getMDCPropertyMap().get("spanId")).whenNotNull();
    }).withNewLineAtEnd();

    @Override
    public String format(ILoggingEvent event) {
        return writer.writeToString(event);
    }

    private static String message(ILoggingEvent event) {
        IThrowableProxy tp = event.getThrowableProxy();
        String msg = event.getFormattedMessage();
        return (tp == null) ? msg : msg + "\n" + ThrowableProxyUtil.asString(tp);
    }

    private static String severity(Level level) {
        return switch (level.toInt()) {
            case Level.ERROR_INT -> "ERROR";
            case Level.WARN_INT -> "WARNING";
            case Level.INFO_INT -> "INFO";
            default -> "DEBUG";
        };
    }
}
