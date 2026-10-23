package jp.pavlov.jpp.web;

import com.google.cloud.spanner.DatabaseClient;
import com.google.cloud.spanner.ResultSet;
import com.google.cloud.spanner.Statement;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * Spanner 全文検索 API（4-data/sql/search-schema.sql と対応）。
 * - 入力不正は 400（Spring MVC のメソッド検証）
 * - Spanner 障害は 503。障害を「0件」に置き換えない
 * - 検索語は値をバインドし、ログに出力しない
 */
@RestController
public class SearchController {

    private static final Logger log = LoggerFactory.getLogger(SearchController.class);

    private static final String SQL = """
            SELECT DocumentId, PublicationNumber, Title, SCORE(SearchTokens, @query) AS Relevance
            FROM PatentSearchDocuments@{FORCE_INDEX=PatentFullText}
            WHERE SEARCH(SearchTokens, @query)
            ORDER BY Relevance DESC, DocumentId
            LIMIT @page_size""";

    private final ObjectProvider<DatabaseClient> spanner;

    public SearchController(ObjectProvider<DatabaseClient> spanner) {
        this.spanner = spanner;
    }

    @GetMapping("/api/search")
    public Map<String, Object> search(
            @RequestParam("q") @NotBlank @Size(max = 256) String query,
            @RequestParam(name = "size", defaultValue = "20") @Min(1) @Max(100) int size) {

        DatabaseClient client = spanner.getIfAvailable();
        if (client == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "search backend is not configured");
        }
        Statement stmt = Statement.newBuilder(SQL)
                .bind("query").to(query)
                .bind("page_size").to(size)
                .build();
        List<Map<String, Object>> items = new ArrayList<>();
        try (ResultSet rs = client.singleUse().executeQuery(stmt)) {
            while (rs.next()) {
                items.add(Map.of(
                        "documentId", rs.getString("DocumentId"),
                        "publicationNumber", rs.getString("PublicationNumber"),
                        "title", rs.getString("Title"),
                        "relevance", rs.getDouble("Relevance")));
            }
        } catch (RuntimeException e) {
            log.error("search failed (query text omitted)", e);
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "search temporarily unavailable");
        }
        return Map.of("count", items.size(), "items", items);
    }
}
