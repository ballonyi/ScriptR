set define off
create or replace and compile java source named tablerow$$ as
import java.util.*;
import java.sql.*;
import java.io.*;
import oracle.jdbc.*;
import java.text.SimpleDateFormat;
import java.lang.Math.*;
import java.util.Base64;
import javax.xml.bind.DatatypeConverter;
import java.lang.IllegalArgumentException;

public class TableRow extends ArrayList<TableColumn>{

    /**
    * read all records of all_tab_columns for then specified table, results stored in ArrayList
    * ArrayList will contain then excluded columns, but the will be marked
    **/
    public void init( String owner, String tableName,String excludedCols ) throws SQLException{
        Connection cn = DriverManager.getConnection("jdbc:default:connection:");
        List<String> exc = null;        
        String sql = null;
        
        if(excludedCols!=null) {
            exc=Arrays.asList(excludedCols.toUpperCase().split("\\s*,\\s*"));
            for( String col : exc){
                System.out.println("exclude: "+col);             
                boolean found=false;
                sql = String.format("select * from all_tab_columns where owner='%s' and table_name='%s' and column_name='%s'", owner, tableName, col);
                try( Statement stmt = cn.createStatement(); ResultSet rs = stmt.executeQuery(sql); ){                                                           
                    while (rs.next()) {
                        found = true;
                    }
                }
                if(!found){
                    throw new IllegalArgumentException(String.format("Invalid column name: %s",col));
                }
            }
        }          
        
        sql = String.format("select * from all_tab_columns where owner='%s' and table_name='%s' order by column_id",
                                   owner, tableName);
        //System.out.println(sql);                                   
        try( Statement stmt = cn.createStatement(); ResultSet rs = stmt.executeQuery(sql); ){
            TableColumn col;
            while (rs.next()) {
            
                col = new TableColumn();
                col.setColumnId(rs.getInt("COLUMN_ID"));                  
                col.setColumnName(rs.getString("COLUMN_NAME"));                
                col.setDataType(rs.getString("DATA_TYPE"));                               
                col.setDataLength(rs.getLong("DATA_LENGTH"));
               
                col.setDataPrecision(rs.getLong("DATA_PRECISION"));
                if(rs.wasNull()){
                    col.setDataPrecision(null);
                }                 
                col.setDataScale(rs.getLong("DATA_SCALE"));
                if(rs.wasNull()){
                    col.setDataScale(null);
                }     
                col.setExcluded(exc!=null && exc.contains(rs.getString("COLUMN_NAME")));              
                add(col);
                System.out.println(col.toString()); 
            }                
        }    
    }

    public void clearValues(){
        for(TableColumn item: this){
            item.getValues().clear();
        }
    }

    public int getNumOfFilledLobColumns(TableRow currentRow){
        int result=0;
        for (TableColumn col : currentRow) {
            if( col.isColumnLobAndFilled() ){
                ++result;
            }
        }
        return result;
    } 
    
    public String joinedFieldList(){
        String result = null;
        for (TableColumn col : this) {
            if( !col.isExcluded() ){   
                result = (result==null) ? col.getColumnName().toLowerCase() : result + "," + col.getColumnName().toLowerCase();
            }
        }
        return result;
    }

    public String joinedValueList(){
        String result = null;
        String append;
        for (TableColumn col : this) {
            if( !col.isExcluded() ){   
                
                if( col.isLob() ){
                    if(col.isColumnLobAndFilled()){
                        append = col.getVariableName();
                    }
                    else {
                        append = col.getValues().get(0);
                    }
                }
                else {
                    append = col.getValues().get(0);
                }
            
                //String append = ( !col.isLob() ) ?  : col.getVariableName();
                result = (result==null) ? append : result + "," + append;
            }
        }
        return result;
    }    

}
/
