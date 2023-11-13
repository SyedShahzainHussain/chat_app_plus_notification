import 'dart:convert';

import 'package:chat_app/firebase/notification_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    notificationService.requestNotificationPermission();
    notificationService.isRefreshToken();
    notificationService.setUpInteractMessage(context);
    notificationService.getDeviceToken().then((value) {
      if (kDebugMode) {
        print(value);
      }
    });
    notificationService.firebaseInit(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Users"),
          actions: [
            PopupMenuButton(
              onSelected: (value) async {
                if (value == "logout") {
                  await FirebaseAuth.instance.signOut();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () {},
                  value: "logout",
                  child: const Text("Logout"),
                )
              ],
            )
          ],
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('user')
              .where("uid",
                  isNotEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("No User"),
              );
            } else {
              return ListView.builder(
                itemBuilder: (context, index) {
                  final data = snapshot.data!.docs[index];

                  return Column(
                    children: [
                      ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                recipientName: data['username'],
                                recipientUid: data['uid'],
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(data['imageUrl']),
                          key: ValueKey(data['uid']),
                        ),
                        title: Text(data['username']),
                      ),
                      const Divider(color: Colors.black, thickness: 1),
                    ],
                  );
                },
                itemCount: snapshot.data!.docs.length,
              );
            }
          },
        ));
  }
}

class ChatScreen extends StatefulWidget {
  final String recipientName;
  final String recipientUid;

  const ChatScreen({
    super.key,
    required this.recipientName,
    required this.recipientUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  NotificationService notificationService = NotificationService();
  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.recipientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_getChatId())
                  .collection("messages")
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Messages!"));
                }

                SchedulerBinding.instance.addPostFrameCallback((_) {
                  scrollController
                      .jumpTo(scrollController.position.minScrollExtent);
                });
                return ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    final isSender = message['senderUid'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    final backgroundColor =
                        isSender ? Colors.grey[300] : Colors.deepPurpleAccent;
                    final textColor = isSender ? Colors.black : Colors.white;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          mainAxisAlignment: isSender
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              width: MediaQuery.sizeOf(context).width * .4,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 10),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isSender
                                      ? const Radius.circular(12)
                                      : const Radius.circular(0),
                                  bottomRight: isSender
                                      ? const Radius.circular(0)
                                      : const Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: isSender
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['username'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    message['text'],
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                    textAlign: isSender
                                        ? TextAlign.end
                                        : TextAlign.start,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          left: isSender
                              ? null
                              : MediaQuery.sizeOf(context).width * .35,
                          right: isSender
                              ? MediaQuery.sizeOf(context).width * .35
                              : null,
                          child: CircleAvatar(
                            backgroundColor: Colors.pink,
                            backgroundImage: NetworkImage(message['imageUrl']),
                          ),
                        )
                      ],
                    );
                  },
                  itemCount: snapshot.data!.docs.length,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type your message here...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('user')
        .doc(currentUser!.uid)
        .get();

    if (_messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_getChatId())
          .collection('messages')
          .add({
        'text': _messageController.text,
        'senderUid': currentUser.uid,
        'recipientUid': widget.recipientUid,
        'timestamp': Timestamp.now(),
        'username': userData['username'],
        'imageUrl': userData['imageUrl']
      });

      notificationService.getDeviceToken().then((value) async {
        final data = {
          "to": value.toString(),
          'priority': 'high',
          "notification": {
            "title": userData['username'],
            "body": _messageController.text.toString()
          },
          "data": {"type": "chats", "id": "123"}
        };
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          body: jsonEncode(data),
          headers: {
            "Content-Type": "application/json; charset=UTF-8",
            'Authorization':
                "key=AAAA5B3OQjE:APA91bFKEMcjRkb9CGDWw7WQzJlDkHpLkOv95FvIGyDji73w7OzF10htzmNqhv07xQb1gK4dotKonABuytrmCUV5VxPufYDxAr2_UuwenbhW9QAPRS7YRGEg4IvGsCcGbxOfC4Ny3UnN"
          },
        );
         _messageController.clear();
      });

     
    }
  }

  String _getChatId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser!.uid.hashCode <= widget.recipientUid.hashCode) {
      return '${currentUser.uid}-${widget.recipientUid}';
    } else {
      return '${widget.recipientUid}-${currentUser.uid}';
    }
  }
}
