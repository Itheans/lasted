import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_string/random_string.dart';

class ChatPage extends StatefulWidget {
  String name, profileurl, username;
  ChatPage(
      {required this.name, required this.profileurl, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Stream? messageStream;
  String? myUsername, myName, myEmail, mypicture, chatRoomid, messageId;
  TextEditingController messagecontroller = new TextEditingController();
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  getthesahredpref() async {
    myUsername = await SharedpreferenceHelper().getUserName();
    myName = await SharedpreferenceHelper().getUserDisplayName();
    myEmail = await SharedpreferenceHelper().getUserEmail();
    mypicture = await SharedpreferenceHelper().getUserImage();

    chatRoomid = await getChatRoomIdbyUsername(  widget.username,myUsername!);
    print(chatRoomid);
    setState(() {});
  }

  bool _isRecording = false;
  String? _filePath;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  Future<void> _initialize() async {
    await _recorder.openRecorder();
    await _requestPermission();
    var tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.aac';
  }

  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
      Navigator.pop(context);
      openRecording();
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      Navigator.pop(context);
      openRecording();
    });
  }

  ontheload() async {
    await getthesahredpref();
    await getandSetMessages();
    setState(() {});
  }

  @override
  void initState() {
    ontheload();
    _initialize();
    super.initState();
  }

  Future<void> _uploadFile() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Your Audio is Uploading Please Wait...",
          style: TextStyle(fontSize: 20.0),
        )));
    File file = File(_filePath!);
    try {
      TaskSnapshot snapshot =
          await FirebaseStorage.instance.ref('uploads/audio.aac').putFile(file);
      String downloadURL = await snapshot.ref.getDownloadURL();
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "Data": "Audio",
        "message": downloadURL,
        "sendBy": myUsername,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": mypicture,
      };
      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomid!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": "Audio",
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername,
        };
        DatabaseMethods()
            .updateLastMessageSend(chatRoomid!, lastMessageInfoMap);
      });
    } catch (e) {
      print('Error uploading to Firebase: $e');
    }
  }

  Widget chatMessageTile(String message, bool sendByMe, String Data) {
    return Row(
      mainAxisAlignment:
          sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
            child: Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomRight:
                      sendByMe ? Radius.circular(0) : Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft:
                      sendByMe ? Radius.circular(30) : Radius.circular(0)),
              color: sendByMe ? Colors.black45 : Colors.blue),
          child: Data == "Image"
              ? Image.network(
                  message,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                )
              : Data == "Audio"
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AudioPlayerScreen(audioUrl: message)));
                      },
                      child: Container(
                        width: 100,
                        child: Row(
                          children: [
                            Icon(
                              Icons.mic,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 10.0,
                            ),
                            Text(
                              "Audio",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Text(
                      message,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
        ))
      ],
    );
  }

  Future<void> _uploadImage() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Your Image is Uploading Please Wait...",
          style: TextStyle(fontSize: 20.0),
        )));

    try {
      String addId = randomAlphaNumeric(10);

      Reference firebaseStorgeRef =
          FirebaseStorage.instance.ref().child("blogImage").child(addId);

      final UploadTask task = firebaseStorgeRef.putFile(selectedImage!);
      var downloadurl1 = await (await task).ref.getDownloadURL();
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "Data": "Image",
        "message": downloadurl1,
        "sendBy": myUsername,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": mypicture,
      };
      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomid!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": "Image",
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername,
        };
        DatabaseMethods()
            .updateLastMessageSend(chatRoomid!, lastMessageInfoMap);
      });
    } catch (e) {
      print('Error uploading to Firebase: $e');
    }
  }

  getandSetMessages() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomid);
    setState(() {});
  }

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    selectedImage = File(image!.path);
    _uploadImage();
    setState(() {});
  }

  Widget chatMessage() {
    return StreamBuilder(
        stream: messageStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return chatMessageTile(
                        ds["message"], myUsername == ds["sendBy"], ds["Data"]);
                  })
              : Container();
        });
  }

  getChatRoomIdbyUsername(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$a\_$b";
    } else {
      return "$b\_$a";
    }
  }

  addMessage(bool sendClicked) async {
    if (messagecontroller.text != "") {
      String message = messagecontroller.text;
      messagecontroller.text = "";

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "Data": "Message",
        "message": message,
        "sendBy": myUsername,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": mypicture,
      };
      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomid!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername,
        };
        DatabaseMethods()
            .updateLastMessageSend(chatRoomid!, lastMessageInfoMap);
        if (sendClicked) {
          message = "";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff703eff),
      body: Container(
        margin: EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 5,
                  ),
                  Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Expanded(
                child: Container(
              padding: EdgeInsets.only(left: 10.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                        height: MediaQuery.of(context).size.height / 1.25,
                        child: chatMessage()),
                    Container(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              openRecording();
                            },
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: Color(0xff703eff),
                                  borderRadius: BorderRadius.circular(60)),
                              child: Icon(
                                Icons.mic,
                                size: 35.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          Expanded(
                            child: Container(
                                padding: EdgeInsets.only(left: 10.0),
                                decoration: BoxDecoration(
                                    color: Color(0xFFececf8),
                                    borderRadius: BorderRadius.circular(10)),
                                child: TextField(
                                  onChanged: (value) {},
                                  controller: messagecontroller,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "Write a message..",
                                      suffixIcon: GestureDetector(
                                          onTap: () {
                                            getImage();
                                          },
                                          child: Icon(Icons.attach_file))),
                                )),
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          GestureDetector(
                            onTap: () {
                              addMessage(true);
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Color(0xff703eff),
                                  borderRadius: BorderRadius.circular(60)),
                              child: Icon(
                                Icons.send,
                                size: 30.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                        ],
                      ),
                    ),
                      SizedBox(
                            height: 10.0,
                          ),
                  ],
                ),
              ),
            ))
          ],
        ),
      ),
    );
  }

  Future openRecording() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
              content: SingleChildScrollView(
                  child: Container(
            child: Column(
              children: [
                Text(
                  "Add Voice Note",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins'),
                ),
                SizedBox(
                  height: 20.0,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_isRecording) {
                      _stopRecording();
                    } else {
                      _startRecording();
                    }
                  },
                  child: Text(
                    _isRecording ? 'Stop Recording' : 'Start Recording',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_isRecording) {
                      null;
                    } else {
                      _uploadFile();
                    }
                  },
                  child: Text(
                    'Upload Audio',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ))));
}
