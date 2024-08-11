import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    messages = context.watch<AppState>().chatMessages;
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
          TextFormField(
            controller: fieldText,
            decoration: const InputDecoration(
              labelText: 'New message',
            ),
            onFieldSubmitted: (value) {
              setState(
                () {
                  messages
                      .add(ChatMessage(author: Author.user, content: value));
                },
              );
              fieldText.clear();
            },
          ),
        ],
      ),
    );
  }
}
