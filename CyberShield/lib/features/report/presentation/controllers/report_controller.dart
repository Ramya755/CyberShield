import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final TextEditingController victimNameController = TextEditingController();
  final TextEditingController victimEmailController = TextEditingController();
  final TextEditingController victimPhoneController = TextEditingController();
  final TextEditingController suspectContactController = TextEditingController();
  final TextEditingController suspiciousLinkController = TextEditingController();
  final TextEditingController appNameController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List<String> states = const [
    'Andaman Nicobar',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra Nagar Haveli and Daman Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  final List<String> scamTypes = const [
    'Fake Message / SMS',
    'Phishing Link',
    'Banking OTP Fraud',
    'UPI Payment Fraud',
    'Fake App',
    'Social Media Scam',
    'Fraud Call',
    'Other Cyber Crime',
  ];

  final Map<String, String> stateEmails = const {
    'Andaman Nicobar': 'spcid.and@nic.in',
    'Andhra Pradesh': 'addlspncrp-cid@ap.gov.in',
    'Arunachal Pradesh': 'sp-si@arunpol.nic.in',
    'Assam': 'digp-cid@assampolice.gov.in',
    'Bihar': 'cybercell-bih@nic.in',
    'Chandigarh': 'dspccic-chd@nic.in',
    'Chhattisgarh': 'aigtech-phq@cg.gov.in',
    'Dadra Nagar Haveli and Daman Diu': 'phq-dd@nic.in',
    'Delhi': 'dcp-ifso@delhipolice.gov.in',
    'Goa': 'spcyber@goapolice.gov.in',
    'Gujarat': 'cc-cid@gujarat.gov.in',
    'Haryana': 'sp-cyber.hry@nic.in',
    'Himachal Pradesh': 'dig-cybercr-hp@nic.in',
    'Jammu Kashmir': 'ssp-cice-jk@jkpolice.gov.in',
    'Jharkhand': 'sp-cid@jhpolice.gov.in',
    'Karnataka': 'spccps-cid@ksp.gov.in',
    'Kerala': 'adgpcyberops.pol@kerala.gov.in',
    'Ladakh': 'soto-igp@police.ladakh.gov.in',
    'Lakshadweep': 'lak-sop@nic.in',
    'Madhya Pradesh': 'spcyber@mp.gov.in',
    'Maharashtra': 'ig.cyber-mah@nic.in',
    'Manipur': 'sp-cybercrime.mn@manipur.gov.in',
    'Meghalaya': 'ccw-meg@gov.in',
    'Mizoram': 'cybercrime.sp@mizoram.gov.in',
    'Nagaland': 'spcyber-ngl@gov.in',
    'Odisha': 'sp1cyber@odishapolice.gov.in',
    'Puducherry': 'cybercell-police.py@gov.in',
    'Punjab': 'aigcyber@punjabpolice.gov.in',
    'Rajasthan': 'sp.cybercrime@rajpolice.gov.in',
    'Sikkim': 'spcid@sikkimpolice.nic.in',
    'Tamil Nadu': 'cbcyber@tn.gov.in',
    'Telangana': 'addldgp-cid@tspolice.gov.in',
    'Tripura': 'spcybercrime@tripurapolice.nic.in',
    'Uttar Pradesh': 'sp-cyber.lu@up.gov.in',
    'Uttarakhand': 'cybercrime.police@uk.gov.in',
    'West Bengal': 'occybercid@westbengal.gov.in',
  };

  String selectedState = 'Andhra Pradesh';
  String selectedScamType = 'Fake Message / SMS';
  bool _isOpeningMail = false;

  bool get isOpeningMail => _isOpeningMail;
  String get selectedOfficialEmail =>
      stateEmails[selectedState] ?? 'cybercrime@nic.in';

  bool get isMessageType => selectedScamType == 'Fake Message / SMS';
  bool get isLinkType => selectedScamType == 'Phishing Link';
  bool get isPaymentType =>
      selectedScamType == 'Banking OTP Fraud' ||
      selectedScamType == 'UPI Payment Fraud';
  bool get isFakeAppType => selectedScamType == 'Fake App';
  bool get isSocialType => selectedScamType == 'Social Media Scam';
  bool get isCallType => selectedScamType == 'Fraud Call';

  void setStateValue(String? value) {
    if (value == null || value == selectedState) return;
    selectedState = value;
    notifyListeners();
  }

  void setScamType(String? value) {
    if (value == null || value == selectedScamType) return;
    selectedScamType = value;
    notifyListeners();
  }

  String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  bool validateFullForm() => formKey.currentState?.validate() ?? false;

  String get generateEmailSubject =>
      'Cyber Crime Complaint - $selectedScamType - $selectedState';

  String get generateSummary {
    final victim = victimNameController.text.trim().isEmpty
        ? 'The victim'
        : victimNameController.text.trim();
    final description = descriptionController.text.trim();
    final shortDescription = description.length > 180
        ? '${description.substring(0, 180)}...'
        : description;

    final details = <String>[];
    if (suspectContactController.text.trim().isNotEmpty) {
      details.add('Suspicious contact: ${suspectContactController.text.trim()}');
    }
    if (suspiciousLinkController.text.trim().isNotEmpty) {
      details.add('Link: ${suspiciousLinkController.text.trim()}');
    }
    if (appNameController.text.trim().isNotEmpty) {
      details.add('App: ${appNameController.text.trim()}');
    }
    if (transactionIdController.text.trim().isNotEmpty) {
      details.add('Transaction ID: ${transactionIdController.text.trim()}');
    }
    if (amountController.text.trim().isNotEmpty) {
      details.add('Amount: ${amountController.text.trim()}');
    }

    return '$victim is reporting $selectedScamType in $selectedState. '
        '${details.isNotEmpty ? '${details.join(', ')}. ' : ''}'
        '${shortDescription.isNotEmpty ? shortDescription : 'Kindly review the complaint and take necessary action.'}';
  }

  String get generateEmailBody {
    final buffer = StringBuffer();
    buffer.writeln('To');
    buffer.writeln('The Cyber Crime Cell');
    buffer.writeln(selectedState);
    buffer.writeln('Email: $selectedOfficialEmail');
    buffer.writeln();
    buffer.writeln('Subject: $generateEmailSubject');
    buffer.writeln();
    buffer.writeln('Respected Sir/Madam,');
    buffer.writeln();
    buffer.writeln(
      'I would like to report a cyber crime incident and request necessary action from your department.',
    );
    buffer.writeln();
    buffer.writeln('Victim Details');
    buffer.writeln('Name: ${victimNameController.text.trim()}');
    buffer.writeln('Email: ${victimEmailController.text.trim()}');
    buffer.writeln('Phone: ${victimPhoneController.text.trim()}');
    buffer.writeln('State/UT: $selectedState');
    buffer.writeln();
    buffer.writeln('Incident Category: $selectedScamType');
    if (suspectContactController.text.trim().isNotEmpty) {
      buffer.writeln(
        'Suspicious Contact Number / ID: ${suspectContactController.text.trim()}',
      );
    }
    if (suspiciousLinkController.text.trim().isNotEmpty) {
      buffer.writeln('Suspicious Link: ${suspiciousLinkController.text.trim()}');
    }
    if (appNameController.text.trim().isNotEmpty) {
      buffer.writeln('App Name: ${appNameController.text.trim()}');
    }
    if (transactionIdController.text.trim().isNotEmpty) {
      buffer.writeln('Transaction ID: ${transactionIdController.text.trim()}');
    }
    if (amountController.text.trim().isNotEmpty) {
      buffer.writeln('Amount: ${amountController.text.trim()}');
    }
    buffer.writeln();
    buffer.writeln('Detailed Description');
    buffer.writeln(descriptionController.text.trim());
    buffer.writeln();
    buffer.writeln(
      'I kindly request you to investigate this matter and take the necessary action at the earliest.',
    );
    buffer.writeln();
    buffer.writeln('Thank you.');
    buffer.writeln();
    buffer.writeln('Sincerely,');
    buffer.writeln(victimNameController.text.trim());
    return buffer.toString();
  }

  Future<bool> openMail() async {
    _isOpeningMail = true;
    notifyListeners();

    try {
      final subject = Uri.encodeComponent(generateEmailSubject);
      final body = Uri.encodeComponent(generateEmailBody);

      final mailtoUri = Uri.parse(
        'mailto:$selectedOfficialEmail?subject=$subject&body=$body',
      );

      if (await launchUrl(mailtoUri, mode: LaunchMode.externalApplication)) {
        _isOpeningMail = false;
        notifyListeners();
        return true;
      }

      final gmailWebUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=${Uri.encodeComponent(selectedOfficialEmail)}&su=$subject&body=$body',
      );

      final openedGmail = await launchUrl(
        gmailWebUri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );

      _isOpeningMail = false;
      notifyListeners();
      return openedGmail;
    } catch (_) {
      _isOpeningMail = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    victimNameController.dispose();
    victimEmailController.dispose();
    victimPhoneController.dispose();
    suspectContactController.dispose();
    suspiciousLinkController.dispose();
    appNameController.dispose();
    transactionIdController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}