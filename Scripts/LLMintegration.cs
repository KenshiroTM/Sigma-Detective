using Godot;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

public class HuggingFaceAPI : Node
{
	private static readonly System.Net.Http.HttpClient client = new System.Net.Http.HttpClient();
	private const string API_URL = "https://api-inference.huggingface.co/models/EleutherAI/gpt-neo-2.7B";
	private const string API_TOKEN = "Sigma_Detective"; // Wstaw swój token

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
			// Wytry
		
			var response = await client.SendAsync(request);
			response.EnsureSuccessStatusCode();
			var responseString = await response.Content.ReadAsStringAsync();

			var responseData = JsonConvert.DeserializeObject<dynamic>(responseString);
			return responseData[0]?.generated_text ?? "Błąd w odpowiedzi API";
		}
		catch (HttpRequestException e)
		{
			return $"Błąd komunikacji: {e.Message}";
		}
	}
	}
