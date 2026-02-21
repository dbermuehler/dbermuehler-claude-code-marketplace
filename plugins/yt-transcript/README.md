# yt-transcript

Extract and analyze YouTube video transcripts directly in Claude Code — no Python, no pip, just `curl` and `jq`.

## What you can do with it

### Summarize a video

Drop a link and get a summary instead of watching the whole thing.

```
/yt-transcript https://youtu.be/dQw4w9WgXcQ
```

### Ask questions about the content

Add a question before or after the URL to get a direct answer from the transcript.

```
/yt-transcript https://youtu.be/dQw4w9WgXcQ What are the key takeaways?
/yt-transcript Does the speaker mention pricing? https://youtu.be/dQw4w9WgXcQ
```

### Have a conversation about the video

After the initial extraction, the full transcript stays in context. Ask follow-up questions without re-running the skill.

```
/yt-transcript https://youtu.be/VIDEO_ID

# then just keep asking:
What counterarguments does the speaker address?
What's discussed around the 15 minute mark?
```

### Turn a coding tutorial into working code

Extract the steps from a tutorial and have Claude implement them directly in your project — no pausing and rewinding.

```
/yt-transcript https://youtu.be/VIDEO_ID Implement the auth flow shown in this tutorial in my project.
```

### Extract every recommendation from a podcast

Hosts and guests constantly drop book titles, tools, papers, and names. Pull all of them into a single list instead of scrubbing through timestamps.

```
/yt-transcript https://youtu.be/VIDEO_ID List every book, tool, and person recommended in this podcast episode.
```

### Pull out the frameworks

Speakers often describe mental models or decision-making processes in passing that get buried in a 90-minute conversation. Easier to spot in text.

```
/yt-transcript https://youtu.be/VIDEO_ID What frameworks or mental models does the speaker describe?
```

