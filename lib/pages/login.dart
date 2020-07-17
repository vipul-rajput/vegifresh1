import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GoogleSignIn googleSignIn = new GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences preferences;
  bool loading;
  bool isLogedin = false;

  @override
  void initState(){
    super.initState();
    isSignedIn();
  }
  void isSignedIn() async {
    setState(() {
      loading = true;
    });
    preferences = await SharedPreferences.getInstance();
    isLogedin = await googleSignIn.isSignedIn();
    if(isLogedin){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
    }
    setState(() {
      loading = false;
    });
  }
  Future handleSignIn() async{
    preferences = await SharedPreferences.getInstance();
    setState(() {
      loading = true;
    });
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication = await googleUser.authentication;
    AuthCredential credential = await GoogleAuthProvider.getCredential(
        idToken: googleSignInAuthentication.idToken, accessToken: googleSignInAuthentication.accessToken
    ); // AuthCredential === firebase of tutor
    await firebaseAuth.signInWithCredential(credential);
    FirebaseUser firebaseUser = await firebaseAuth.currentUser();
    if(AuthCredential != null){
      final QuerySnapshot result = await Firestore.instance.collection("users").where("id", isEqualTo: AuthCredential).getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length == 0){
        Firestore.instance.collection("user").document(firebaseUser.uid).setData({
          "id" : firebaseUser.uid,
          "username": firebaseUser.displayName,
          "profilePicture": firebaseUser.photoUrl,
        });
        await preferences.setString("id",firebaseUser.uid);
        await preferences.setString("username", firebaseUser.displayName);
        await preferences.setString("photoUrl", firebaseUser.displayName);//errpr
      } else{
        await preferences.setString("id", documents[0]['id']);
        await preferences.setString("username", documents[0]['username']);
        await preferences.setString("photoUrl", documents[0]['photoUrl']);
      }
      Toast.show("Logged in Successful", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
      setState(() {
        loading = false;
      });
    }else{}
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "login",
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: new Text("Login", style: TextStyle(color: Colors.red),),
            elevation: 0.1,
          ),
          body: Stack(
            children: <Widget>[
              Center(
                child: FlatButton(
                  color: Colors.red,
                  onPressed: (){
                    handleSignIn();
                  }, child: Text("Sign In"),
                ),
              ),
              Visibility(
                visible: loading ?? true,
                child: Container(
                    color: Colors.white.withOpacity(0.7),
                    child: CircularProgressIndicator(
                      valueColor:  AlwaysStoppedAnimation<Color>(Colors.red),
                    )
                ),
              )
            ],
          ),
        )
    );
  }
}

