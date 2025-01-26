using Godot;
using System;
using System.Collections.Generic;

public partial class Story : Resource
{
    public string storyDesc { get; set; }
    public List<string> peopleNames { get; set; }
    public List<string> characterStartingPrompts { get; set; }
    public List<bool> guiltyPeople { get; set; }
}
