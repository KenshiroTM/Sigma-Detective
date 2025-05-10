using Godot;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

// Dodaj alias dla HttpClient
using SystemNetHttpClient = System.Net.Http.HttpClient;

public partial class TogetherAI : Node
{
	// Użyj aliasu dla HttpClient
	private static readonly SystemNetHttpClient client = new SystemNetHttpClient();
	private const string API_URL = "";
	private const string API_TOKEN = ""; // Wklej swój klucz API!

	public async Task<string> SendPrompt(string prompt)
	{
		// Poprawny format zapytania do Together AI
		var requestBody = new
		{
			model = "meta-llama/Llama-Vision-Free",
			messages = new[]
			{
				new { role = "user", content = prompt }
			}
		};

		var jsonContent = JsonConvert.SerializeObject(requestBody);
		var request = new System.Net.Http.HttpRequestMessage(HttpMethod.Post, API_URL);
		request.Headers.Add("Authorization", $"Bearer {API_TOKEN}");
		request.Content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

		try
		{
			// Wysłanie zapytania
			var response = await client.SendAsync(request);
			string responseString = await response.Content.ReadAsStringAsync();

			if (!response.IsSuccessStatusCode)
			{
				GD.PrintErr($"Błąd API: {response.StatusCode} - {responseString}");
				return "Błąd w zapytaniu!";
			}

			// Parsowanie JSON
			var responseData = JObject.Parse(responseString);
			return responseData["choices"]?[0]?["message"]?["content"]?.ToString() ?? "Brak odpowiedzi!";
		}
		catch (HttpRequestException e)
		{
			GD.PrintErr($"Błąd komunikacji: {e.Message}");
			return "Błąd komunikacji z API!";
		}
	}
}
