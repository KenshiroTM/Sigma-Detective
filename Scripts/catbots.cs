uusing Godot;
using System.Threading.Tasks;

public class ChatbotManager : Node
{
	private HuggingFaceAPI bot1API = new HuggingFaceAPI();
	private HuggingFaceAPI bot2API = new HuggingFaceAPI();
	private HuggingFaceAPI bot3API = new HuggingFaceAPI();

	// to do przypisania uwu
	[Export] private LineEdit InputField;
	[Export] private Label OutputLabelBot1;
	[Export] private Label OutputLabelBot2;
	[Export] private Label OutputLabelBot3;

	public async void OnSendMessageButtonPressed()
	{
		string userInput = InputField.Text;

		// Odpowiedzi 
		string responseBot1 = await bot1API.SendPrompt($"Chatbot 1: {userInput}");
		string responseBot2 = await bot2API.SendPrompt($"Chatbot 2: {userInput}");
		string responseBot3 = await bot3API.SendPrompt($"Chatbot 3: {userInput}");

	  
		OutputLabelBot1.Text = $"Bot 1: {responseBot1}";
		OutputLabelBot2.Text = $"Bot 2: {responseBot2}";
		OutputLabelBot3.Text = $"Bot 3: {responseBot3}";

		// Czyszczenie pola wprowadzania tekstu
		InputField.Text = "";
	}
}
