using Godot;
using System;
using System.Collections.Generic;

public partial class allStories : Node
{
    public static List<Story> stories = new List<Story>()
    {
        new Story("desc", new List<string>{"one","two","three" }, new List<bool>{ false, true, false }),
        new Story("desc1", new List<string>{"one","two","three" }, new List<bool>{ false, true, false }),
        new Story("desc2", new List<string>{"one","two","three" }, new List<bool>{ false, true, false }),
    };

    public static Story getRandomStory()
    {

        Random rand = new Random();
        int i = (int)rand.Next(0, stories.Count);
        return stories[i];
    }
}
