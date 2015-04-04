package customudf;

import java.io.IOException;
import org.apache.pig.EvalFunc;
import org.apache.pig.data.Tuple;
import java.sql.Timestamp;

public class fromunixtime extends EvalFunc<String> {

	@Override
	//Conversion from Unix to java.sql.Timestamp
	public String exec(Tuple arg0) throws IOException {

		if (arg0 == null || arg0.size() == 0 || arg0.get(0) == null) {
			Long time_null = 1l;
			Timestamp ts_null = new Timestamp(time_null);
			return ts_null.toString();
		}
			
		try {
			Long time_long = Long.parseLong(arg0.get(0).toString());
			Timestamp ts = new Timestamp(time_long);
			return ts.toString();
		}
		
		catch (Exception e) {			
			throw new IOException("Something unexpected happened!" 
			+ e.getMessage(), e);
		}
	}

}
