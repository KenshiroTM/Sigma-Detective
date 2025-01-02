using Godot;
using System;

public class GameManager
{
    public static string gameScene = "res://Scenes/Game/Game.tscn";
    public static string menuScene = "res://Scenes/MainMenu/MainMenu.tscn";

    public enum GameState
    {
        MainMenu,
        InGame,
        GameMenu,
        GameWon,
        GameLost
    }

    public static GameState gameState = GameState.MainMenu;
    // TODO: global script
    
}