package customudf;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.pig.EvalFunc;
import org.apache.pig.data.Tuple;

public class kisscounter extends EvalFunc<Integer> {

	@Override
	// Count the number of word "kiss" occurrences
	public Integer exec(Tuple arg0) throws IOException {
		
		if (arg0 == null || arg0.size() == 0 || arg0.get(0) == null) {
			return -1;
		}
			
		try	{
			Integer love = 0;
			Pattern pattern = Pattern.compile("целую", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
			Matcher matcher = pattern.matcher(arg0.get(0).toString());
			
            while(matcher.find()) {
            	love++;
            }
            
		return love;
		}
		
		catch (Exception e) {
			throw new IOException("Something unexpected happened!" 
			+ e.getMessage(), e);
		}
	}

}
