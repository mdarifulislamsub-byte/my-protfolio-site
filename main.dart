import 'dart:typed_data';
// Conditional Import: Web-এ থাকলে dart:html পাবে, অ্যান্ড্রয়েডে থাকলে stub ফাইলটি রিড করবে
import 'web_helper_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // প্ল্যাটফর্ম চেকের জন্য
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
// ফাইলটির একদম শুরুতে এই লাইনটি অবশ্যই থাকতে হবে (যদি না থাকে দিয়ে দিন):
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // এখন এটি কাজ করবে
import 'package:cloud_firestore/cloud_firestore.dart'; // নতুন যুক্ত হয়েছে
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp( // এখান থেকে const সরিয়ে দিন
    debugShowCheckedModeBanner: false,
    home: PortfolioScreen(),
  ));
}

class CertificateData {
  String name;
  Uint8List? bytes;
  String? imageUrl;

  // নিচের মতো করে লিখলে এরর হবে না
  CertificateData({required this.name, this.bytes, this.imageUrl});
}

class ExperienceData {
  String companyName;
  String date;
  String designation;
  String description;
  List<CertificateData> certificates;

  ExperienceData({
    this.companyName = '',
    this.date = '',
    this.designation = '',
    this.description = '',
    List<CertificateData>? certificates,
  }) : this.certificates = certificates ?? [];
}

// NEW: Project Data Model
class ProjectData {
  String projectName;
  String title;
  String challengesAndSolutions;
  String keyFeatures;
  String githubUrl;
  String codeSnippet;
  List<Uint8List> mediaFiles;

  ProjectData({
    this.projectName = '',
    this.title = '',
    this.challengesAndSolutions = '',
    this.keyFeatures = '',
    this.githubUrl = '',
    this.codeSnippet = '',
    List<Uint8List>? mediaFiles,
  }) : this.mediaFiles = mediaFiles ?? [];
}

// --- Main Portfolio Screen ---

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  List<Map<String, dynamic>> _experiences = [];

  @override
  void initState() {
    super.initState();
    _loadDataFromFirestore();
  }
  Future<void> _updateContactField(String key, String value) async {
    try {
      // ৯৩ নম্বর লাইন থেকে ৯৬ নম্বর লাইন পর্যন্ত এটি বসান
      Map<String, dynamic> dataToUpdate = {};
      dataToUpdate[key] = value; // এখানে [key] ব্যবহার করলে আপনার ভেরিয়েবলের মানটি ফিল্ডের নাম হবে
      await FirebaseFirestore.instance
          .collection('my_portfolio')
          .doc('user_data')
          .set(dataToUpdate, SetOptions(merge: true));

      // ডাটা সেভ হওয়ার পর লোকাল ভেরিয়েবল আপডেট করুন
      setState(() {
        if (key == 'emailAddress') emailAddress = value;
        if (key == 'phoneNumber') phoneNumber = value;
        if (key == 'linkedinUrl') linkedinUrl = value;
      });

      print("SUCCESS: $key updated to $value");
    } catch (e) {
      print("ERROR: $e");
    }
  }
  Future<void> _savePersonalInfo() async {
    try {
      await FirebaseFirestore.instance
          .collection('my_portfolio')
          .doc('user_data')
          .set({
        'colam4': colam4,
        'colam5': colam5,
        'colam6': colam6,
        'aboutMe': aboutMe,
        'operationalDomain': operationalDomain,
        // এই তিনটি লাইন অবশ্যই যোগ করবেন:
        'emailAddress': emailAddress,
        'phoneNumber': phoneNumber,
        'linkedinUrl': linkedinUrl,
      }, SetOptions(merge: true));

      debugPrint("Personal information saved successfully.");
    } catch (e) {
      debugPrint("Error saving personal information: $e");
    }
  }
// এই ফাংশনটি এখন ক্লাসের সদস্য, কোনো ফাংশনের ভেতরে নেই
  void _showFullNetworkImageDialog(BuildContext context, String imageUrl, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }

  void _loadDataFromFirestore() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('my_portfolio').doc('user_data').get();
      if (snapshot.exists) {
        var data = snapshot.data();

        setState(() {
          // ১. Experiences লোড করা
          var expData = data?['experiences'] ?? [];
          _experiences = List<Map<String, dynamic>>.from(expData);
          experiencesList = _experiences.map((e) => ExperienceData(
            companyName: e['companyName'] ?? '',
            date: e['date'] ?? '',
            designation: e['designation'] ?? '',
            description: e['description'] ?? '',
            certificates: (e['certificates'] as List<dynamic>?)?.map((c) {
              return CertificateData(
                name: c['name'] ?? '',
                imageUrl: c['imageUrl'],
              );
            }).toList() ?? [],
          )).toList();
          var projectData = data?['projects'] ?? [];
          projectsList = List<Map<String, dynamic>>.from(projectData)
              .map((e) => ProjectData(
            projectName: e['projectName'] ?? '',
            title: e['title'] ?? '',
            challengesAndSolutions: e['challengesAndSolutions'] ?? '',
            keyFeatures: e['keyFeatures'] ?? '',
            githubUrl: e['githubUrl'] ?? '',
            codeSnippet: e['codeSnippet'] ?? '',
            mediaFiles: [],
          ))
              .toList();

          // ২. Dashboard Image URL লোড করা (আপনার যদি একটি স্ট্রিং ভেরিয়েবল থাকে)
          if (data != null && data.containsKey('dashboardImage')) {
            // ধরে নিচ্ছি আপনি dashboardImageUrl নামে একটি String ভেরিয়েবল ব্যবহার করছেন
            // যদি না থাকে, তবে উপরে String? dashboardImageUrl; ঘোষণা করে নিন
            dashboardImageUrl = data['dashboardImage'];
            print("Dashboard URL from Firestore: $dashboardImageUrl");
          }
          // ১৮০ নম্বর লাইনের পর থেকে দেখুন:
          colam4 = data?['colam4'] ?? colam4;
          colam5 = data?['colam5'] ?? colam5;
          colam6 = data?['colam6'] ?? colam6;
          aboutMe = data?['aboutMe'] ?? aboutMe;
          operationalDomain = data?['operationalDomain'] ?? operationalDomain;

          // এই তিনটি লাইন এখানে বসান (এটি আনুমানিক ১৮৫-১৮৭ নম্বর লাইন হবে):
          emailAddress = data?['emailAddress'] ?? "";
          phoneNumber = data?['phoneNumber'] ?? "";
          linkedinUrl = data?['linkedinUrl'] ?? "";
        }); // setState শেষ হচ্ছে
        print("Data and Dashboard Image loaded successfully!");
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  String profileName = "ARIFUL'S PORTFOLIO";
  Uint8List? dashboardImageBytes;
  String? dashboardImageUrl;

  Uint8List? resumePdfBytes;
  String resumePdfName = "";

  String emailAddress = "";
  String phoneNumber = "";
  String linkedinUrl = "";

  String colam4 = "4";
  String colam5 = "5";
  String colam6 = "6.";
  String aboutMe = "7.";
  String operationalDomain = "8.";

  List<ExperienceData> experiencesList = [];
  // NEW: Global Project List State
  List<ProjectData> projectsList = [];

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  void _viewSelectedPdf() {
    if (resumePdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF uploaded yet! Please add from Personal Section.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (kIsWeb) {
      final blob = html.Blob([resumePdfBytes!], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, "_blank");
      html.Url.revokeObjectUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF Viewing is only supported on Web platform. Please use Download instead on mobile.')),
      );
    }
  }

  void _downloadSelectedPdf() {
    if (resumePdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF uploaded yet to download!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (kIsWeb) {
      final blob = html.Blob([resumePdfBytes!], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", resumePdfName.isNotEmpty ? resumePdfName : "resume.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF downloading native to mobile storage requires path providers. Preview active on Web only.')),
      );
    }
  }

  void _showFullImageDialog(BuildContext context, Uint8List imageBytes, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(fontSize: 16)),
              backgroundColor: const Color(0xFF000080),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: Personal Page Navigation Function ---
  void _navigateToPersonalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalDetailsPage(
          currentName: profileName,
          currentMail: emailAddress,
          currentPhone: phoneNumber,
          currentLinkedin: linkedinUrl,
          currentColam4: colam4,
          currentColam5: colam5,
          currentColam6: colam6,
          currentAboutMe: aboutMe,
          currentOpDomain: operationalDomain,
          currentExperiences: experiencesList,
          currentProjects: projectsList,
          currentPdfName: resumePdfName,
          onNameUpdated: (newName) => setState(() => profileName = newName),
          onImageUpdated: (newImageBytes) => setState(() => dashboardImageBytes = newImageBytes),
          onMailUpdated: (mail) => setState(() => emailAddress = mail),
          onPhoneUpdated: (phone) => setState(() => phoneNumber = phone),
          onLinkedinUpdated: (link) => setState(() => linkedinUrl = link),
          onColam4Updated: (val) async {
            setState(() => colam4 = val);
            await _savePersonalInfo();
          },

          onColam5Updated: (val) async {
            setState(() => colam5 = val);
            await _savePersonalInfo();
          },

          onColam6Updated: (val) async {
            setState(() => colam6 = val);
            await _savePersonalInfo();
          },

          onAboutMeUpdated: (val) async {
            setState(() => aboutMe = val);
            await _savePersonalInfo();
          },

          onOpDomainUpdated: (val) async {
            setState(() => operationalDomain = val);
            await _savePersonalInfo();
          },
          onExperiencesUpdated: (updatedList) => setState(() => experiencesList = updatedList),
          onProjectsUpdated: (updatedProjList) => setState(() => projectsList = updatedProjList),
          onPdfUploaded: (bytes, name) {
            setState(() {
              resumePdfBytes = bytes;
              resumePdfName = name;
            });
          },
        ),
      ),
    );
  }

  // --- NEW: Admin Password Validation Dialog ---
  void _showPasswordDialog(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Admin Access"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Enter Password",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000080)),
              onPressed: () {
                // আপনি চাইলে এখানে "1234" পরিবর্তন করে নিজের পাসওয়ার্ড দিতে পারেন
                if (passwordController.text == "1234") {
                  Navigator.pop(context);
                  _navigateToPersonalPage();
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect Password!'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text("Login", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // UPDATED: Dynamic Project Dialog with Page View, Custom 1,2,3 Indicator & Bottom GitHub Location
  void _showProjectDisplayDialog(BuildContext context) {
    final PageController projectPageController = PageController();
    int activeProjectIndex = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double screenWidth = MediaQuery.of(context).size.width;
            double dialogWidth = screenWidth > 1000 ? 1000 : screenWidth * 0.95;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: dialogWidth,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Dashboard Projects",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF000080)),
                    ),
                    const Divider(thickness: 2),
                    const SizedBox(height: 10),
                    projectsList.isEmpty
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Text("No projects added yet. Please config from Personal Section."),
                      ),
                    )
                        : Flexible(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: PageView.builder(
                          controller: projectPageController,
                          itemCount: projectsList.length,
                          onPageChanged: (index) {
                            setDialogState(() {
                              activeProjectIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final proj = projectsList[index];
                            return SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(proj.projectName.isNotEmpty ? proj.projectName.toUpperCase() : "PROJECT NAME",
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                    ),
                                    const SizedBox(height: 5),
                                    Center(
                                      child: Text(proj.title.isNotEmpty ? proj.title : "Title Not Added",
                                          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
                                    ),
                                    const SizedBox(height: 15),
                                    // Responsive Row/Column for Challenges & Features
                                    screenWidth > 600
                                        ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildProjectInfoBox("Challenges & Solutions:", proj.challengesAndSolutions)),
                                        const SizedBox(width: 15),
                                        Expanded(child: _buildProjectInfoBox("Key Features:", proj.keyFeatures)),
                                      ],
                                    )
                                        : Column(
                                      children: [
                                        _buildProjectInfoBox("Challenges & Solutions:", proj.challengesAndSolutions),
                                        const SizedBox(height: 15),
                                        _buildProjectInfoBox("Key Features:", proj.keyFeatures),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    const Text("Tech Stack:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5),
                                    const Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt, color: Colors.blue), Text(" Flutter")]),
                                        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.code, color: Colors.cyan), Text(" Dart")]),
                                        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.local_fire_department, color: Colors.orange), Text(" Firebase")]),
                                        Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.api, color: Colors.green), Text(" REST APIs")]),
                                      ],
                                    ),
                                    if (proj.mediaFiles.isNotEmpty) ...[
                                      const SizedBox(height: 15),
                                      const Text("Live Demo Gallery:", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 100,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: proj.mediaFiles.length,
                                          itemBuilder: (context, mIndex) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 10),
                                              child: InkWell(
                                                onTap: () => _showFullImageDialog(context, proj.mediaFiles[mIndex], "Media Asset"),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.memory(proj.mediaFiles[mIndex], width: 100, fit: BoxFit.cover),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    ],
                                    if (proj.codeSnippet.isNotEmpty) ...[
                                      const SizedBox(height: 15),
                                      const Text("Code Preview (Android Studio Dark Theme):", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(10)),
                                        child: Text(
                                          proj.codeSnippet,
                                          style: const TextStyle(color: Color(0xFFA9B7C6), fontFamily: 'monospace', fontSize: 13),
                                        ),
                                      )
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Bottom Navigation Row with GitHub Button & 1, 2, 3 Pagination Sequence
                    if (projectsList.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // GitHub Repo Launcher Button positioned in the red marked bottom layout
                          if (projectsList[activeProjectIndex].githubUrl.isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              icon: const Icon(Icons.link, color: Colors.white, size: 18),
                              label: const Text("Open GitHub Repo", style: TextStyle(color: Colors.white, fontSize: 13)),
                              onPressed: () => _launchURL(projectsList[activeProjectIndex].githubUrl),
                            )
                          else
                            const SizedBox(height: 40),
                          const SizedBox(width: 15),
                          // Dynamic Numbered Indicator Sequence (1, 2, 3...)
                          if (projectsList.length > 1)
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(projectsList.length, (idx) {
                                    bool isCurrent = idx == activeProjectIndex;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: InkWell(
                                        onTap: () {
                                          projectPageController.animateToPage(
                                            idx,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isCurrent ? const Color(0xFF000080) : Colors.grey.shade200,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          child: Center(
                                            child: Text(
                                              "${idx + 1}",
                                              style: TextStyle(
                                                color: isCurrent ? Colors.white : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF000080),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectInfoBox(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000080))),
          const SizedBox(height: 5),
          Text(content.isNotEmpty ? content : "N/A"),
        ],
      ),
    );
  }

  void _showExperienceDisplayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double screenWidth = MediaQuery.of(context).size.width;
        double dialogWidth = screenWidth > 1000 ? 1000 : screenWidth * 0.95;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Work Experience & Certificates",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF000080)),
                ),
                const Divider(thickness: 2),
                const SizedBox(height: 15),
                experiencesList.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text("No experience added yet. Please add from Personal Section."),
                  ),
                )
                    : Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: experiencesList.length,
                    itemBuilder: (context, index) {
                      final exp = experiencesList[index];
                      if (exp.companyName.isEmpty && exp.designation.isEmpty && exp.description.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exp.companyName.isNotEmpty ? exp.companyName.toUpperCase() : "COMPANY NAME",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              const SizedBox(height: 8),
                              Text("Designation: ${exp.designation.isNotEmpty ? exp.designation : 'N/A'}", style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text("Duration: ${exp.date.isNotEmpty ? exp.date : 'N/A'}", style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(exp.description.isNotEmpty ? exp.description : 'No description provided.'),
                              if (exp.certificates.isNotEmpty) ...[
                                const SizedBox(height: 15),
                                const Text("Attached Certificates (Click to view):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: exp.certificates.length,
                                    itemBuilder: (context, cIndex) {
                                      final cert = exp.certificates[cIndex];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: InkWell(
                                          onTap: () {
                                            if (cert.bytes != null) {
                                              // আগের ফাংশন: যদি ছবিটি সরাসরি মোবাইল মেমোরিতে থাকে
                                              _showFullImageDialog(context, cert.bytes!, cert.name);
                                            } else if (cert.imageUrl != null && cert.imageUrl!.isNotEmpty) {
                                              // নতুন ফাংশন: যদি ছবিটি ফায়ারবেসের লিঙ্কে থাকে
                                              _showFullNetworkImageDialog(context, cert.imageUrl!, cert.name);
                                            }
                                          },
                                          child: Tooltip(
                                            message: cert.name,
                                            child: Container(
                                              width: 80,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.shade300),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(7),
                                                child: cert.bytes != null
                                                    ? Image.memory(cert.bytes!, fit: BoxFit.cover)
                                                    : (cert.imageUrl != null && cert.imageUrl!.isNotEmpty)
                                                    ? Image.network(cert.imageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image))
                                                    : const Icon(Icons.image, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000080)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(0),
        minScale: 0.5,
        maxScale: 1.0,
        panEnabled: true,
        constrained: false,
        child: SizedBox(
          width: screenWidth < 1200 ? 1200 : screenWidth,
          child: Column(
            children: [
              // Navigation Header Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                color: const Color(0xFF000080),
                child: Row(
                  children: [
                    Text(profileName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                    const Spacer(),
                    ...["Home", "Resume/CV", "My Project", "Experience", "Expertise"]
                        .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          if (e == "Resume/CV") _showCvDialog(context);
                          if (e == "Experience") _showExperienceDisplayDialog(context);
                          if (e == "My Project") _showProjectDisplayDialog(context);
                        },
                        child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ))
                        .toList(),
                    const SizedBox(width: 12),

                    // UPDATED: Hamburger Menu replacing old Personal button with Password verification
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                      offset: const Offset(0, 50),
                      onSelected: (value) {
                        if (value == 'Personal') {
                          _showPasswordDialog(context);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Personal',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: Color(0xFF000080)),
                              SizedBox(width: 10),
                              Text('Personal', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000080))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildHeroContent(context)),
                        const SizedBox(width: 40),
                        Expanded(
                            child: Container(
                              height: 350,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                                // ৮০০ নম্বর লাইন থেকে শুরু:
                                image: dashboardImageUrl != null
                                    ? DecorationImage(
                                  image: NetworkImage(dashboardImageUrl! + "&t=" + DateTime.now().millisecondsSinceEpoch.toString()),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ), // এখানে একটি ব্র্যাকেট ) এবং কমা , হবে
                              child: dashboardImageUrl == null
                                  ? const Center(child: Icon(Icons.image, size: 60, color: Colors.grey))
                                  : null,
                            )),
                      ],
                    ),
                    const SizedBox(height: 80),
                    _buildFooterSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCvDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf, size: 60, color: Color(0xFF000080)),
                const SizedBox(height: 20),
                Text(resumePdfBytes != null ? "Resume / CV Loaded" : "No CV Uploaded", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (resumePdfName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(resumePdfName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000080)),
                    onPressed: () {
                      Navigator.pop(context);
                      _viewSelectedPdf();
                    },
                    child: const Text("View CV", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadSelectedPdf();
                    },
                    child: const Text("Download", style: TextStyle(color: Color(0xFF000080))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterSection() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _footerItem("Technical Stack", "Flutter, Dart, Firebase, REST APIs, Git."),
    _footerItem("Operational Domain", operationalDomain),
    _footerItem("About Me", aboutMe)
  ]);

  Widget _footerItem(String title, String content) => Expanded(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Divider(color: Colors.black, thickness: 2),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 5),
            Text(content, style: const TextStyle(color: Colors.black54, fontSize: 16))
          ])));

  Widget _buildHeroContent(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(colam4, style: const TextStyle(color: Colors.orange)),
      Text(colam5, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
      Text(colam6),
      const SizedBox(height: 20),
      ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000080), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20)),
          onPressed: () {
            _showContactDialog(context);
          },
          child: const Text("Contact Now", style: TextStyle(color: Colors.white))),
    ],
  );

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Contact Information", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                _contactOption(Icons.mail, "Mail", Colors.blue, () {
                  if (emailAddress.isNotEmpty) _launchURL("mailto:$emailAddress");
                }),
                _contactOption(Icons.phone, "WhatsApp ", Colors.green, () {
                  if (phoneNumber.isNotEmpty) {
                    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
                    _launchURL("https://web.whatsapp.com/send?phone=$cleanNumber");
                  }
                }),
                _contactOption(Icons.link, "LinkedIn", Colors.indigo, () {
                  if (linkedinUrl.isNotEmpty) {
                    String formattedUrl = linkedinUrl.startsWith("http") ? linkedinUrl : "https://$linkedinUrl";
                    _launchURL(formattedUrl);
                  }
                }),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _contactOption(IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 20),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Personal Details Panel Section ---


class PersonalDetailsPage extends StatelessWidget {
  final String currentName;
  final String currentMail;
  final String currentPhone;
  final String currentLinkedin;
  final String currentColam4;
  final String currentColam5;
  final String currentColam6;
  final String currentAboutMe;
  final String currentOpDomain;
  final List<ExperienceData> currentExperiences;
  final List<ProjectData> currentProjects;
  final String currentPdfName;

  final Function(String) onNameUpdated;
  final Function(Uint8List) onImageUpdated;
  final Function(String) onMailUpdated;
  final Function(String) onPhoneUpdated;
  final Function(String) onLinkedinUpdated;
  final Function(String) onColam4Updated;
  final Function(String) onColam5Updated;
  final Function(String) onColam6Updated;
  final Function(String) onAboutMeUpdated;
  final Function(String) onOpDomainUpdated;
  final Function(List<ExperienceData>) onExperiencesUpdated;
  final Function(List<ProjectData>) onProjectsUpdated;

  final Function(Uint8List, String) onPdfUploaded;

  const PersonalDetailsPage({
    super.key,
    required this.currentName,
    required this.currentMail,
    required this.currentPhone,
    required this.currentLinkedin,
    required this.currentColam4,
    required this.currentColam5,
    required this.currentColam6,
    required this.currentAboutMe,
    required this.currentOpDomain,
    required this.currentExperiences,
    required this.currentProjects,
    required this.currentPdfName,
    required this.onNameUpdated,
    required this.onImageUpdated,
    required this.onMailUpdated,
    required this.onPhoneUpdated,
    required this.onLinkedinUpdated,
    required this.onColam4Updated,
    required this.onColam5Updated,
    required this.onColam6Updated,
    required this.onAboutMeUpdated,
    required this.onOpDomainUpdated,
    required this.onExperiencesUpdated,
    required this.onProjectsUpdated,
    required this.onPdfUploaded,
  });

  void _pickPdfFile(BuildContext context) {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.pdf';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();

          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            final Uint8List fileBytes = reader.result as Uint8List;
            onPdfUploaded(fileBytes, file.name);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${file.name} saved successfully!'), backgroundColor: Colors.green),
            );
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploading via HTML elements is only available on Web.')),
      );
    }
  }

  void _showContactEditDialog(BuildContext context, String title, String hint, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(controller: controller, maxLines: null, decoration: InputDecoration(hintText: hint)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showNameEditDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile Name"),
          content: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Enter your name")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                onNameUpdated(nameController.text);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDashboardImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final Uint8List imageBytes =
      await pickedFile.readAsBytes();

      onImageUpdated(imageBytes);

      String imageUrl =
      await uploadDashboardImage(imageBytes);

      await FirebaseFirestore.instance
          .collection("my_portfolio")
          .doc("user_data")
          .set({
        "dashboardImage": imageUrl,
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Dashboard Photo uploaded successfully!"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF000080),
        title: const Text("ADD PERSONAL DETAILS", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: screenWidth > 800
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLeftFormColumn(context)),
            const SizedBox(width: 30),
            Expanded(child: _buildRightFormColumn(context)),
          ],
        )
            : Column(
          children: [
            _buildLeftFormColumn(context),
            _buildRightFormColumn(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftFormColumn(BuildContext context) {
    return Column(children: [
      _premiumRow(context, "1", currentPdfName.isNotEmpty ? "Resume: $currentPdfName" : "Resume (No file selected)", "Select PDF CV", () => _pickPdfFile(context)),
      _premiumRow(context, "2", "Profile name", "Add Profile name", () {
        _showNameEditDialog(context);
      }),
      _premiumThreeRow(
        context,
        "3",
        "Mail",
            () => _showContactEditDialog(context, "Edit Mail Address", "example@mail.com", currentMail, onMailUpdated),
        "Phone",
            () => _showContactEditDialog(context, "Edit WhatsApp Number", "e.g. 6512345678", currentPhone, onPhoneUpdated),
        "Linkedin",
            () => _showContactEditDialog(context, "Edit LinkedIn Link", "linkedin.com/in/username", currentLinkedin, onLinkedinUpdated),
      ),
      _premiumRow(context, "4", "Colam-4", "Add Description", () {
        _showContactEditDialog(context, "Edit Colam-4 Text", "Enter text for hero top section", currentColam4, onColam4Updated);
      }),
      _premiumRow(context, "5", "Colam-5", "Add Description", () {
        _showContactEditDialog(context, "Edit Colam-5 Text", "Enter bold main text", currentColam5, onColam5Updated);
      }),
      _premiumRow(context, "6", "Colam-6", "Add Description", () {
        _showContactEditDialog(context, "Edit Colam-6 Text", "Enter hero description subtext", currentColam6, onColam6Updated);
      }),
      _premiumRow(context, "7", "About me", "Add Description", () {
        _showContactEditDialog(context, "Edit About Me Text", "Enter details for About Me footer section", currentAboutMe, onAboutMeUpdated);
      }),
    ]);
  }

  Widget _buildRightFormColumn(BuildContext context) {
    return Column(children: [
      _premiumRow(context, "8", "Operational Domain", "Add Description", () {
        _showContactEditDialog(context, "Edit Operational Domain Text", "Enter text for Operational Domain footer section", currentOpDomain, onOpDomainUpdated);
      }),
      _premiumRow(context, "9", "Dashboard Photo", "Add Dashboard Photo", () {
        _pickDashboardImage(context);
      }),
      _premiumRow(context, "10", "My Project", "Add My Project", () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectFormPage(
              initialProjects: currentProjects,
              onSave: onProjectsUpdated,
            ),
          ),
        );
      }),
      _premiumRow(context, "11", "Experience", "Add Experience", () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExperienceFormPage(
              initialExperiences: currentExperiences,
              onSave: onExperiencesUpdated,
            ),
          ),
        );
      }),
      _premiumRow(context, "12", "Expertise", "Add Experience", () {}),
      _premiumRow(context, "13", "Additional", "Add Description", () {}),
      _premiumRow(context, "14", "Additional", "Add Description", () {}),
    ]);
  }

  Widget _premiumRow(BuildContext context, String no, String title, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(no, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF000080)))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 3))]),
              child: Row(children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                if (action.isNotEmpty) TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)))
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumThreeRow(BuildContext context, String no, String t1, VoidCallback onTap1, String t2, VoidCallback onTap2, String t3, VoidCallback onTap3) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 30, child: Text(no, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF000080)))),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [_subItem(t1, onTap1), _subItem(t2, onTap2), _subItem(t3, onTap3, isLast: true)]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subItem(String label, VoidCallback onTap, {bool isLast = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200))),
    child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 15))), TextButton(onPressed: onTap, child: const Text("Add details", style: TextStyle(fontWeight: FontWeight.bold)))]),
  );
}

// --- Experience Management Section ---

class ExperienceFormPage extends StatefulWidget {
  final List<ExperienceData> initialExperiences;
  final Function(List<ExperienceData>) onSave;

  const ExperienceFormPage({super.key, required this.initialExperiences, required this.onSave});

  @override
  State<ExperienceFormPage> createState() => _ExperienceFormPageState();
}

class _ExperienceFormPageState extends State<ExperienceFormPage> {
  final List<ExperienceData> _tempExperiences = [];
  int _currentIndex = 0;

  late TextEditingController _companyController;
  late TextEditingController _dateController;
  late TextEditingController _designationController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    if (widget.initialExperiences.isNotEmpty) {
      for (var exp in widget.initialExperiences) {
        _tempExperiences.add(ExperienceData(
          companyName: exp.companyName,
          date: exp.date,
          designation: exp.designation,
          description: exp.description,
          certificates: List.from(exp.certificates),
        ));
      }
    } else {
      _tempExperiences.add(ExperienceData());
    }
    _initControllers();
  }

  void _initControllers() {
    final currentExp = _tempExperiences[_currentIndex];
    _companyController = TextEditingController(text: currentExp.companyName);
    _dateController = TextEditingController(text: currentExp.date);
    _designationController = TextEditingController(text: currentExp.designation);
    _descriptionController = TextEditingController(text: currentExp.description);
  }

  void _saveCurrentState() {
    _tempExperiences[_currentIndex].companyName = _companyController.text;
    _tempExperiences[_currentIndex].date = _dateController.text;
    _tempExperiences[_currentIndex].designation = _designationController.text;
    _tempExperiences[_currentIndex].description = _descriptionController.text;
  }
  Future<void> _saveAllDataToFirestore() async {
    // ১২৬৫ নম্বর লাইনে এটি বসান:
    final storage = FirebaseStorage.instance;
    print("Storage is ready: $storage");

    try {
      _saveCurrentState();
      // ... বাকি কোড

      // এক্সপেরিয়েন্স লিস্টের ডাটাগুলোকে ফায়ারবেসের জন্য ম্যাপে কনভার্ট করছি
      // এখানে async যোগ করতে হবে
      final expData = await Future.wait(_tempExperiences.map((e) async {
        return {
          'companyName': e.companyName,
          'date': e.date,
          'designation': e.designation,
          'description': e.description,
          'certificates': await Future.wait(e.certificates.map((c) async {
            String? imageUrl;
            if (c.bytes != null) {
              imageUrl = await uploadFileToStorage(c.bytes!, c.name);
            }
            return {
              'name': c.name,
              'imageUrl': imageUrl,
            };
          }).toList()),
        };
      }).toList());
      // ফায়ারবেসে ডাটা পাঠাচ্ছি
      await FirebaseFirestore.instance.collection('my_portfolio').doc('user_data').set({
        'experiences': expData,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved to Firestore!')),
      );
    } catch (e) {
      print("Error saving to Firestore: $e");
    }
  }

  Future<void> _pickCertificate() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _tempExperiences[_currentIndex].certificates.add(
          CertificateData(name: file.name, bytes: bytes),
        );
      });
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _dateController.dispose();
    _designationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF000080),
        title: Text("Experience Entry Box (${_currentIndex + 1}/${_tempExperiences.length})"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: screenWidth > 900 ? 900 : screenWidth * 0.95,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField("Company name", _companyController),
                const SizedBox(height: 20),
                _buildInputField("Date", _dateController),
                const SizedBox(height: 20),
                _buildInputField("Designation", _designationController),
                const SizedBox(height: 20),
                _buildInputField("Description:", _descriptionController, maxLines: 8),
                const SizedBox(height: 20),
                if (_tempExperiences[_currentIndex].certificates.isNotEmpty) ...[
                  const Text("Selected Certificates Preview:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: _tempExperiences[_currentIndex].certificates.map((cert) {
                      return Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: cert.bytes != null ? Image.memory(cert.bytes!, fit: BoxFit.cover) : const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _tempExperiences[_currentIndex].certificates.remove(cert);
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.cancel, color: Colors.red, size: 22),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                screenWidth > 600
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCertificateControls(),
                    const Spacer(),
                    _buildActionControls(),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCertificateControls(),
                    const SizedBox(height: 25),
                    _buildActionControls(),
                  ],
                ),
                if (_tempExperiences.length > 1) ...[
                  const SizedBox(height: 30),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Previous Block"),
                        onPressed: _currentIndex > 0
                            ? () {
                          _saveCurrentState();
                          setState(() {
                            _currentIndex--;
                            _initControllers();
                          });
                        }
                            : null,
                      ),
                      Text("Block ${_currentIndex + 1} of ${_tempExperiences.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("Next Block"),
                        onPressed: _currentIndex < _tempExperiences.length - 1
                            ? () {
                          _saveCurrentState();
                          setState(() {
                            _currentIndex++;
                            _initControllers();
                          });
                        }
                            : null,
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBlueprintButton("Add Certificate", _pickCertificate),
        const SizedBox(height: 10),
        Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4A90E2), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _tempExperiences[_currentIndex].certificates.isNotEmpty ? _tempExperiences[_currentIndex].certificates.last.name : "Certificate name",
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 10),
        _buildBlueprintButton("Add more certificate", _pickCertificate),
      ],
    );
  }

  Widget _buildActionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ১৪৫৬ নম্বর লাইন থেকে ১৪৬০ নম্বর লাইনের অংশটি এভাবে পরিবর্তন করুন:
        _buildBlueprintButton("Save Data", () {
          _saveCurrentState();
          widget.onSave(_tempExperiences);

          // নতুন এই লাইনটি এখানে বসিয়ে দিন:
          _saveAllDataToFirestore();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Experience data saved successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }),
        const SizedBox(height: 10),
        _buildBlueprintButton("Add more Experience", () {
          _saveCurrentState();
          setState(() {
            _tempExperiences.add(ExperienceData());
            _currentIndex = _tempExperiences.length - 1;
            _initControllers();
          });
        }),
      ],
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF000080), width: 2),
        ),
      ),
    );
  }

  Widget _buildBlueprintButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF4A90E2), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// --- Project Creator Form Page Section ---

class ProjectFormPage extends StatefulWidget {
  final List<ProjectData> initialProjects;
  final Function(List<ProjectData>) onSave;

  const ProjectFormPage({super.key, required this.initialProjects, required this.onSave});

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final List<ProjectData> _tempProjects = [];
  int _currentIndex = 0;

  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _challengesController;
  late TextEditingController _featuresController;

  @override
  void initState() {
    super.initState();
    if (widget.initialProjects.isNotEmpty) {
      for (var p in widget.initialProjects) {
        _tempProjects.add(ProjectData(
          projectName: p.projectName,
          title: p.title,
          challengesAndSolutions: p.challengesAndSolutions,
          keyFeatures: p.keyFeatures,
          githubUrl: p.githubUrl,
          codeSnippet: p.codeSnippet,
          mediaFiles: List.from(p.mediaFiles),
        ));
      }
    } else {
      _tempProjects.add(ProjectData());
    }
    _initControllers();
  }

  void _initControllers() {
    final currentProj = _tempProjects[_currentIndex];
    _nameController = TextEditingController(text: currentProj.projectName);
    _titleController = TextEditingController(text: currentProj.title);
    _challengesController = TextEditingController(text: currentProj.challengesAndSolutions);
    _featuresController = TextEditingController(text: currentProj.keyFeatures);
  }

  void _saveCurrentState() {
    _tempProjects[_currentIndex].projectName = _nameController.text;
    _tempProjects[_currentIndex].title = _titleController.text;
    _tempProjects[_currentIndex].challengesAndSolutions = _challengesController.text;
    _tempProjects[_currentIndex].keyFeatures = _featuresController.text;
  }
  Future<void> _saveProjectsToFirestore() async {
    try {
      _saveCurrentState();

      final projectData = _tempProjects.map((p) {
        return {
          'projectName': p.projectName,
          'title': p.title,
          'challengesAndSolutions': p.challengesAndSolutions,
          'keyFeatures': p.keyFeatures,
          'githubUrl': p.githubUrl,
          'codeSnippet': p.codeSnippet,
          'mediaFiles': [],
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('my_portfolio')
          .doc('user_data')
          .set({
        'projects': projectData,
      }, SetOptions(merge: true));

      print("Projects saved successfully.");
    } catch (e) {
      print("Project save error: $e");
    }
  }
  Future<void> _pickLiveDemoMedia() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      for (var file in files) {
        final bytes = await file.readAsBytes();
        setState(() {
          _tempProjects[_currentIndex].mediaFiles.add(bytes);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media files added successfully to Live Demo!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showCodeEditorDialog() {
    TextEditingController codeController = TextEditingController(text: _tempProjects[_currentIndex].codeSnippet);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 800,
          height: 550,
          color: const Color(0xFF2B2B2B),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text("Android Studio IDE - Code Editor Panel", style: TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'monospace')),
                ],
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: TextField(
                  controller: codeController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Color(0xFFA9B7C6), fontFamily: 'monospace', fontSize: 14, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: "// Paste or write your production ready code template here...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white60))),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B6EAF)),
                    onPressed: () {
                      _tempProjects[_currentIndex].codeSnippet = codeController.text;
                      Navigator.pop(context);
                    },
                    child: const Text("Apply Code Snippet"),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showGitHubLinkDialog() {
    TextEditingController urlController = TextEditingController(text: _tempProjects[_currentIndex].githubUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add GitHub Link"),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: "https://github.com/username/project_repo"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _tempProjects[_currentIndex].githubUrl = urlController.text;
              Navigator.pop(context);
            },
            child: const Text("Save Git Link"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF000080),
        title: Text("Project Blueprint Entry Box (${_currentIndex + 1}/${_tempProjects.length})"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Container(
            width: screenWidth > 900 ? 900 : screenWidth * 0.95,
            color: Colors.white,
            child: Column(
              children: [
                _buildCustomBox("Project Name", _nameController, maxLines: 1, alignment: TextAlign.center),
                const SizedBox(height: 15),
                _buildCustomBox("Title", _titleController, maxLines: 2, alignment: TextAlign.center),
                const SizedBox(height: 20),
                screenWidth > 600
                    ? Row(
                  children: [
                    Expanded(child: _buildCustomBox("Challenges & Solutions\nProblem:\nSolution", _challengesController, maxLines: 6)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildCustomBox("Key Features", _featuresController, maxLines: 6)),
                  ],
                )
                    : Column(
                  children: [
                    _buildCustomBox("Challenges & Solutions\nProblem:\nSolution", _challengesController, maxLines: 5),
                    const SizedBox(height: 15),
                    _buildCustomBox("Key Features", _featuresController, maxLines: 5),
                  ],
                ),
                const SizedBox(height: 25),
                screenWidth > 600
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTechHighlightSection(),
                    const Spacer(),
                    _buildProjectFormActions(),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTechHighlightSection(),
                    const SizedBox(height: 20),
                    _buildProjectFormActions(),
                  ],
                ),
                const SizedBox(height: 35),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildBlueprintButton("Save Setup", () async {
                      _saveCurrentState();
                      widget.onSave(_tempProjects);

                      await _saveProjectsToFirestore();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Project structure configuration updated!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.pop(context);
                    }),
                    const SizedBox(width: 15),
                    _buildBlueprintButton("Add more", () {
                      _saveCurrentState();
                      setState(() {
                        _tempProjects.add(ProjectData());
                        _currentIndex = _tempProjects.length - 1;
                        _initControllers();
                      });
                    }),
                  ],
                ),
                if (_tempProjects.length > 1) ...[
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _currentIndex > 0
                            ? () {
                          _saveCurrentState();
                          setState(() {
                            _currentIndex--;
                            _initControllers();
                          });
                        }
                            : null,
                        child: const Text("Previous Project"),
                      ),
                      Text("Structure Block ${_currentIndex + 1} of ${_tempProjects.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: _currentIndex < _tempProjects.length - 1
                            ? () {
                          _saveCurrentState();
                          setState(() {
                            _currentIndex++;
                            _initControllers();
                          });
                        }
                            : null,
                        child: const Text("Next Project"),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechHighlightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Stack Highlighting", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent), borderRadius: BorderRadius.circular(8)),
          child: const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt, color: Colors.blue, size: 18), Text(" Flutter ", style: TextStyle(fontWeight: FontWeight.bold))]),
              Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.code, color: Colors.cyan, size: 18), Text(" Dart ", style: TextStyle(fontWeight: FontWeight.bold))]),
              Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.local_fire_department, color: Colors.orange, size: 18), Text(" Firebase ", style: TextStyle(fontWeight: FontWeight.bold))]),
              Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.api, color: Colors.green, size: 18), Text(" REST APIs ", style: TextStyle(fontWeight: FontWeight.bold))]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectFormActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildBlueprintButton("View live demo", _pickLiveDemoMedia),
        _buildBlueprintButton("view code", _showCodeEditorDialog),
        _buildBlueprintButton("view on GitHub", _showGitHubLinkDialog),
      ],
    );
  }

  Widget _buildCustomBox(String hint, TextEditingController controller, {required int maxLines, TextAlign alignment = TextAlign.start}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4A90E2), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        textAlign: alignment,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.all(15),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBlueprintButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF4A90E2), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
Future<String> uploadFileToStorage(Uint8List fileBytes, String fileName) async {
  try {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('certificates/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    UploadTask uploadTask = ref.putData(fileBytes);
    TaskSnapshot taskSnapshot = await uploadTask;

    return await taskSnapshot.ref.getDownloadURL();
  } catch (e) {
    print("Upload error: $e");
    return "";
  }
}
// এই ফাংশনটি আপনার _PortfolioScreenState ক্লাসের ভেতরে (নিচে) বসান
void _showFullNetworkImageDialog(BuildContext context, String imageUrl, String name) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    ),
  );
}
Future<String> uploadDashboardImage(Uint8List imageBytes) async {
  try {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('dashboard/dashboard_image.jpg');

    UploadTask uploadTask = ref.putData(imageBytes);

    TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    print("Dashboard Upload Error: $e");
    return "";
  }
}

