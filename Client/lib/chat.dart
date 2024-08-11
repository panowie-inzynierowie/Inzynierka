import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:inzynierka_client/classes/chat.dart';
import 'package:inzynierka_client/state/state.dart';

class ChatDialog extends StatefulWidget {
  const ChatDialog({Key? key}) : super(key: key);

  @override
  ChatDialogState createState() => ChatDialogState();
}

class ChatDialogState extends State<ChatDialog> {
  List<ChatMessage> messages = [];
  final fieldText = TextEditingController();

  final SpeechToText _speechToText = SpeechToText();
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    messages = context.watch<AppState>().chatMessages;
  }

  void _startListening() async {
    setState(() {
      _listening = true;
    });
    await _speechToText.listen(onResult: _onSpeechResult);
  }

  void _stopListening() async {
    setState(() {
      _listening = false;
    });
    await _speechToText.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    fieldText.value = TextEditingValue(text: result.recognizedWords);
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width * 0.7;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: message.author == Author.user
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: message.author == Author.user
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.author == Author.user
                                ? context.watch<AppState>().username
                                : 'System',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: maxWidth,
                            child: Text(
                              message.content,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: fieldText,
                    decoration: const InputDecoration(
                      labelText: 'New message',
                    ),
                    onFieldSubmitted: (value) {
                      setState(
                        () {
                          messages.add(
                              ChatMessage(author: Author.user, content: value));
                        },
                      );
                      fieldText.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: _listening
                      ? const Icon(Icons.mic_off)
                      : const Icon(Icons.mic),
                  onPressed: () {
                    if (_speechToText.isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
