create or replace and compile java source named tablecolumn$$ as
import java.util.Date;
import java.util.*;

public class TableColumn {

    private int columnId;
    private String columnName;    
    private String dataType;
    private Long dataLength;
    private Long dataPrecision;
    private Long dataScale;
    private boolean excluded;
    private ArrayList<String> values;

    public TableColumn() {
        values=new ArrayList<>();
    }

    public int getColumnId() {
        return columnId;
    }

    public void setColumnId(int columnId) {
        this.columnId = columnId;
    }

    public void setColumnName(String columnName) {
        this.columnName = columnName;
    }

    public String getColumnName() {
        return columnName;
    }

    public void setDataType(String dataType) {
        this.dataType = dataType;
    }

    public String getDataType() {
        return dataType;
    }

    public void setDataLength(Long dataLength) {
        this.dataLength = dataLength;
    }

    public Long getDataLength() {
        return dataLength;
    }

    public void setDataPrecision(Long dataPrecision) {
        this.dataPrecision = dataPrecision;
    }

    public Long getDataPrecision() {
        return dataPrecision;
    }
       
    public void setDataScale(Long dataScale) {
        this.dataScale = dataScale;
    }

    public Long getDataScale() {
        return dataScale;
    }

    public void setExcluded(boolean excluded) {
        this.excluded = excluded;
    }

    public boolean isExcluded() {
        return excluded;
    }
    
    public void setValues(ArrayList<String> values){
        this.values=values;
    }
    
    public ArrayList<String> getValues(){
        return values;
    }

    public boolean isLob(){
        return getDataType().equals("CLOB") ||getDataType().equals("BLOB");
    }

    public boolean isColumnLobAndFilled(){
        return (getDataType().equals("CLOB") ||getDataType().equals("BLOB")) && getValues().size()>1;
    }

    public String getVariableName(){        
        if( isLob() ){
            return  String.format("%s_%d",getDataType().toLowerCase(),getColumnId() );
        } else {
            return null;
        }
    }

    public String getVariableDefinition(){        
        if( isLob() ){
            return  String.format("%s %s",getVariableName(),getDataType().toLowerCase() );
        } else {
            return null;
        }
    }

    public String toString(){
        return "TableColumn { columnId="+columnId+
        ", columnName='"+columnName+"'"+
        ", dataType='"+dataType+"'"+
        ", dataLength="+dataLength+
        ", dataPrecision="+dataPrecision+
        ", dataScale="+dataScale+
        ", excluded="+excluded+"";                        
    }

}
/
