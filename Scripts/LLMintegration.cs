using Godot;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

public partial class HuggingFaceAPI
{ 
	private static readonly System.Net.Http.HttpClient client = new System.Net.Http.HttpClient();
	private const string API_URL = "https://api.together.xyz/v1/chat/completions";
	private const string API_TOKEN = "e61825b570641dcb59bda2f606438b58476b24e4f801c98e21f8a49a872e3c6d"; // Wstaw swój token

	public async Task<string> SendPrompt(string prompt)
	{
		// Przygotowanie żądania
		var requestBody = new { inputs = prompt };
		var jsonContent = JsonConvert.SerializeObject(requestBody);
		var request = new System.Net.Http.HttpRequestMessage(HttpMethod.Post, API_URL);
		request.Headers.Add("Authorization", $"Bearer {API_TOKEN}");
		request.Content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

		try
		{
			// Wysłanie zapytania
			var response = await client.SendAsync(request);
			response.EnsureSuccessStatusCode();
			var responseString = await response.Content.ReadAsStringAsync();

			// odp
			var responseData = JsonConvert.DeserializeObject<dynamic>(responseString);
			return responseData[0]?.generated_text ?? "Błąd w odpowiedzi API";
		}
		catch (HttpRequestException e)
		{
			return $"Błąd komunikacji: {e.Message}";
		}
	}
}
