import java.util.UUID;

public class UUIDGenerator {
	public static String genUuid()
	{
		UUID uuid = UUID.randomUUID();
		return uuid.toString();
	}
}
