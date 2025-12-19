package service.admin;

import java.io.InputStream;
import java.util.Map;

public interface ExcelImportService {
    Map<String, Object> importExcel(InputStream excelStream) throws Exception;
}
