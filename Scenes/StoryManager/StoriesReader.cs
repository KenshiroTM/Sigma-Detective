using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

public partial class StoriesReader : Resource
{
    public static Random rand = new Random();
    public static string pathname = "res://Scenes/StoryManager/Stories.json";

    public static List<Story> LoadStories(string pathname)
    {
        if (Godot.FileAccess.FileExists(pathname))
        {
            string jsonData = Godot.FileAccess.GetFileAsString(pathname);
            
            List<Story> stories = JsonSerializer.Deserialize<List<Story>>(jsonData);
            return stories;
        }
        else
        {
            GD.PrintErr("Cannot find stories file!");
        }
        return null;
    }

    public static Story GetRandomStory()
    {
        List<Story> stories = LoadStories(pathname);
        GD.Print(stories);
        int i = (int)rand.Next(0, stories.Count);
        return stories[i];
    }
}
