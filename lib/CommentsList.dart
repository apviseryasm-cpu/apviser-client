// import 'dart:convert';
//
// import 'models/CommentsDTO.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import './models/PostsDTO.dart';
// import './models/ReactedUsersDTO.dart';
// import 'main.dart';
//
// class CommentsListView extends StatelessWidget {
//   final PostDTO postDTO;
//   const CommentsListView({Key? key, required this.postDTO}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//
//     return  Scaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.green,
//           title: Text(postDTO.descr.toString()),
//           centerTitle: true,
//           leading: BackButton(
//             color: Colors.black,
//           ),
//         ),
//         body: SingleChildScrollView (
//           child:  Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: <Widget>[
//
//                   Flexible(
//                       flex: 1,
//                       child:
//                       FutureBuilder(
//                           future: getRelatedItemSingle(postDTO.questionId!, 1073),
//                           builder:(context, AsyncSnapshot snapshot) {
//                             if (snapshot.hasData == false) {
//                               return Center(child: CircularProgressIndicator());
//                             } else {
//                               return Container(
//                                   child: ListView.builder(
//                                       shrinkWrap: true,
//                                       physics: NeverScrollableScrollPhysics(),
//                                       itemCount: snapshot.data.length,
//                                       scrollDirection: Axis.vertical,
//                                       itemBuilder: (BuildContext context, int index) {
//                                         return CommentCardList(snapshot.data[index]);
//                                       }
//                                   )
//                               );
//                             }
//                           }
//                       )
//                   )
//
//                   // ),
//                 ],
//               )
//             ],
//           ),
//         )
//       // )
//
//       // ),
//     );
//   }
//
//   // Widget buildListView(historyRecords) {
//   //   return FutureBuilder<List<ReactedUsersDTO>>(
//   //     future: getRelatedItemSingle(postDTO.questionId, 1073), // Here you run the check for all queryRows items and assign the fromContact property of each item
//   //     builder: (context, snapshot) {
//   //       ListView.builder(
//   //         itemCount: historyRecords.length,
//   //         itemBuilder: (context, index) {
//   //           if (historyRecords[index].fromContact) { // Check if the record is in Contacts
//   //             // True: Return your UI element with Name and Avatar here
//   //           } else {
//   //             // False: Return UI element without Name and Avatar
//   //           }
//   //         },
//   //       );
//   //     },
//   //   );
//   // }
//
//   Future<List<CommentsDTO>> getRelatedItemSingle(int questionID, int userID) async {
//     var list;
//     try {
//       final url = Uri.parse("http://localhost/apviserphp/web/WS/user/getCommentsByQuestionID/");
//       Map<String, String> requestBody = <String, String> {
//         //'json': '{"question_id":${questionID},"user_id":${userID}}'
//         'json': '{"question_id":${questionID},"parent_id":0,"user_id":${userID},"question_comments_limit":20,"comment_comments_limit":2}'
//       };
//
//       Map<String, String> headers = <String, String>{
//         'Authorization':'Basic ${base64Encode(utf8.encode('raza:raza'))}',
//         'Accept': 'application/json',
//         "Access-Control-Allow-Origin": "*",
//       };
//       var request = http.MultipartRequest('POST', url)
//         ..headers.addAll(headers)
//         ..fields.addAll(requestBody);
//       var response = await request.send();
//       final respStr = await response.stream.bytesToString();
//       //print(
//       if(response.statusCode == 200){
//         final parsed = jsonDecode(respStr);
//         final parsed2=parsed['comments'];
//         list =List<CommentsDTO>.from(parsed2.map((model)=> CommentsDTO.fromJson(model)));
//
//         //final parsed3=parsed[0];
//       }
//     } catch (error) {
//       throw Exception('Failed to fetch posts');
//     }finally{
//       return list;
//     }
//   }
//
//   Future _getThingsOnStartup() async {
//     await Future.delayed(Duration(seconds: 2));
//   }
//
// }
//
// // class ReactedUsersCard extends StatelessWidget {
// //   ReactedUsersDTO reactedUsersDTO;
// //
// //   ReactedUsersCard(this.reactedUsersDTO);
// //
// //   String setPostImage() {
// //     String photo = "${reactedUsersDTO.photo}";
// //
// //     if(photo == null) {
// //       return "";
// //     } else{
// //       return "http://localhost/apviserphp/images/$photo";
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     var root;
// //     return IntrinsicHeight(
// //         child:InkWell(
// //           child: Row(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               Flexible(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Container(
// //                         color: Colors.pink,
// //                         margin: const EdgeInsets.only(bottom: 20.0),
// //                         child: Row(
// //                           mainAxisAlignment: MainAxisAlignment.start,
// //                           children: <Widget>[
// //                             Center(
// //                                 child: (
// //                                     Stack(
// //                                       children: <Widget>[
// //                                         Container(
// //                                           width: 50.0,
// //                                           height: 50.0,
// //                                           decoration: BoxDecoration(
// //                                             color: const Color(0xff7c94b6),
// //                                             image: DecorationImage(
// //                                               image: NetworkImage("http://localhost/apviserphp/images/${reactedUsersDTO.photo}"),
// //                                               fit: BoxFit.cover,
// //                                             ),
// //                                             borderRadius: BorderRadius.all( Radius.circular(50.0)),
// //                                             border: Border.all(
// //                                               color: Colors.black,
// //                                               width: 1,
// //                                             ),
// //                                           ),
// //                                         ),
// //                                         Positioned(
// //                                             top: 30,
// //                                             left: 30,
// //                                             height:20,
// //                                             width: 20,
// //                                             child: Container(
// //                                                 child: Image.asset(reactedUsersDTO.ratedPoints=="10"?'images/green_poll.png':reactedUsersDTO.ratedPoints=="5"?'images/yellow_poll.png':'images/red_poll.png', fit: BoxFit.cover, height: 20, width: 20)
// //                                             ))
// //                                       ],
// //                                     )
// //                                 )
// //                             ),
// //                             Padding(
// //                               padding: const EdgeInsets.only(left:5, bottom: 10, right: 0, top:0), //apply padding to some sides only
// //                               child: Text(
// //                                 "${reactedUsersDTO.fullName}",
// //                                 style: const TextStyle(
// //                                   fontSize: 15,
// //                                   fontWeight: FontWeight.w300,
// //                                   fontFamily: 'arial',
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         )),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         )
// //     );
// //   }
// // }
// //
// // class NormalPollSummaryRow extends StatelessWidget {
// //   PostDTO postDTO;
// //
// //   NormalPollSummaryRow(this.postDTO);
// //
// //   String setPostImage() {
// //     String _postImage = "${postDTO.postImage}";
// //
// //     if(_postImage == null) {
// //       return "";
// //     } else{
// //       return "http://localhost/apviserphp/images/$_postImage";
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     var root;
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //       children: <Widget>[
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Text("All"),
// //             Text(" 2"),
// //           ],
// //         ),
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             TextButton(
// //               child: Image.asset('images/green_poll.png',
// //                   fit: BoxFit.cover, height: 30, width: 30),
// //               onPressed: () {
// //                 /* ... */
// //               },
// //             ),
// //             Text(" ${postDTO.best}"),
// //           ],
// //         ),
// //
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             TextButton(
// //               child: Image.asset('images/yellow_poll.png',
// //                   fit: BoxFit.cover, height: 30, width: 30),
// //               onPressed: () {
// //                 /* ... */
// //               },
// //             ),
// //             Text(" ${postDTO.good}"),
// //           ],
// //         ),
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             TextButton(
// //               child: Image.asset('images/red_poll.png',
// //                   fit: BoxFit.cover, height: 30, width: 30),
// //               onPressed: () {
// //                 /* ... */
// //               },
// //             ),
// //             Text(" ${postDTO.poor}"),
// //           ],
// //         ),
// //       ],
// //     );
// //   }
// // }
//
// /*class AnswerPollSummaryRow extends StatelessWidget {
//   PostDTO postDTO;
//
//   AnswerPollSummaryRow(this.postDTO);
//
//   String setPostImage() {
//     String _postImage = "${postDTO.postImage}";
//
//     if(_postImage == null) {
//       return "";
//     } else{
//       return "http://localhost/apviserphp/images/$_postImage";
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: <Widget>[
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text("${postDTO.answerCount}"),
//             Text(" Answers"),
//           ],
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text("${postDTO.bumpCount}"),
//             Text(" Bumps"),
//           ],
//         ),
//
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text("0"),
//             Text(" Shares"),
//           ],
//         ),
//
//       ],
//     );
//   }
// }*/