import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/report_controller.dart';

const Color kMailBgTop = Color(0xFF030B2D);
const Color kMailBgBottom = Color(0xFF060C24);
const Color kMailCyan = Color(0xFF42D7FF);
const Color kMailViolet = Color(0xFF9A63FF);
const Color kMailTextMuted = Color(0xFFAAB6D3);

class MailScreen extends StatelessWidget {
  const MailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ReportController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Mail'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        backgroundColor: kMailBgBottom,
      ),
      backgroundColor: kMailBgBottom,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kMailBgTop, kMailBgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardBlock(
                      title: 'Official Support Mail',
                      child: SelectableText(
                        controller.selectedOfficialEmail,
                        style: const TextStyle(
                          color: kMailCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CardBlock(
                      title: 'Mail Subject',
                      child: SelectableText(
                        controller.generateEmailSubject,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CardBlock(
                      title: 'Generated Mail',
                      child: SelectableText(
                        controller.generateEmailBody,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CardBlock(
                      title: 'Summarized Mail',
                      child: SelectableText(
                        controller.generateSummary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CardBlock(
                      title: 'Guidance',
                      child: const Text(
                        'Attach the supporting files in the mail before sending it.',
                        style: TextStyle(
                          color: kMailTextMuted,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kMailViolet.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: controller.isOpeningMail
                            ? null
                            : () async {
                                final ok = await controller.openMail();
                                if (!context.mounted) return;
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open the mail app or mail web compose window.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMailViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: controller.isOpeningMail
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.mail_outline_rounded),
                        label: Text(
                          controller.isOpeningMail ? 'Opening...' : 'Open Mail',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const CardBlock({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: kMailCyan.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kMailCyan,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}