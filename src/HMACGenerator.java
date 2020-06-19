import java.nio.charset.StandardCharsets;
import java.util.Base64;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class HMACGenerator {
	
	private static final String sha256 = "HmacSHA256";
	
	public static String genSign(String secret, String message)
	{
		
		String sign = new String();
		Mac sha256Hmac;
		
		try {
			
			final byte[] hmacKey = Base64.getDecoder().decode(secret);
			sha256Hmac = Mac.getInstance(sha256);
			SecretKeySpec secretSpec = new SecretKeySpec(hmacKey, sha256);
			sha256Hmac.init(secretSpec);
			byte[] macData = sha256Hmac.doFinal(message.getBytes(StandardCharsets.UTF_8));
			sign = Base64.getEncoder().encodeToString(macData);
			
			//System.out.println("Secret: " + secret);
			//System.out.println("message: " + message);
			//System.out.println("Sign: " + sign);
			
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return sign;
	}
}
