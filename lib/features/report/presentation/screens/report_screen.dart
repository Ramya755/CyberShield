import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/report_controller.dart';
import '../widgets/report_text_field.dart';
import 'mail_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  static const Color bgTop = Color(0xFF030B2D);
  static const Color bgBottom = Color(0xFF060C24);
  static const Color textMuted = Color(0xFFAAB6D3);
  static const Color cyan = Color(0xFF42D7FF);
  static const Color violet = Color(0xFF9A63FF);
  static const Color teal = Color(0xFF1DE9B6);
  static const Color red = Color(0xFFFF5F73);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ReportController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporting'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: bgBottom,
        elevation: 0,
      ),
      backgroundColor: bgBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cyber Scam Reporting Form',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fill the details clearly to generate the official complaint mail.',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),

                  GlowSectionCard(
                    title: 'Victim Details',
                    glowColor: cyan,
                    child: Column(
                      children: [
                        ReportTextField(
                          label: 'Victim Name',
                          hint: 'Enter full name',
                          controller: controller.victimNameController,
                          validator: controller.requiredValidator,
                        ),
                        const SizedBox(height: 16),
                        ReportTextField(
                          label: 'Victim Email',
                          hint: 'Enter email like name@gmail.com',
                          controller: controller.victimEmailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: controller.emailValidator,
                        ),
                        const SizedBox(height: 16),
                        ReportTextField(
                          label: 'Phone Number',
                          hint: 'Enter phone number',
                          controller: controller.victimPhoneController,
                          keyboardType: TextInputType.number,
                          onlyNumbers: true,
                          validator: controller.phoneValidator,
                        ),
                        const SizedBox(height: 16),
                        GlowDropdownField(
                          label: 'State / UT',
                          value: controller.selectedState,
                          items: controller.states,
                          onChanged: controller.setStateValue,
                          glowColor: cyan,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Support Email: ${controller.selectedOfficialEmail}',
                            style: const TextStyle(
                              color: cyan,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Incident Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: CategoryGlowCard(
                          title: 'Fake Message / SMS',
                          icon: Icons.sms_rounded,
                          color: teal,
                          isSelected: controller.isMessageType,
                          onTap: () =>
                              controller.setScamType('Fake Message / SMS'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CategoryGlowCard(
                          title: 'Phishing Link',
                          icon: Icons.link_rounded,
                          color: cyan,
                          isSelected: controller.isLinkType,
                          onTap: () =>
                              controller.setScamType('Phishing Link'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: CategoryGlowCard(
                          title: 'Banking OTP Fraud',
                          icon: Icons.password_rounded,
                          color: red,
                          isSelected:
                              controller.selectedScamType == 'Banking OTP Fraud',
                          onTap: () =>
                              controller.setScamType('Banking OTP Fraud'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CategoryGlowCard(
                          title: 'Other Cyber Crime',
                          icon: Icons.gpp_maybe_rounded,
                          color: violet,
                          isSelected:
                              controller.selectedScamType ==
                              'Other Cyber Crime',
                          onTap: () =>
                              controller.setScamType('Other Cyber Crime'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  GlowSectionCard(
                    title: 'Suspicious Details',
                    glowColor: teal,
                    child: Column(
                      children: [
                        if (controller.isMessageType ||
                            controller.isSocialType ||
                            controller.isCallType) ...[
                          ReportTextField(
                            label: 'Suspicious Contact Number / ID',
                            hint: 'Enter suspicious contact details',
                            controller: controller.suspectContactController,
                            validator: controller.requiredValidator,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (controller.isLinkType) ...[
                          ReportTextField(
                            label: 'Suspicious Link',
                            hint: 'Paste suspicious link',
                            controller: controller.suspiciousLinkController,
                            validator: controller.requiredValidator,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (controller.isPaymentType) ...[
                          ReportTextField(
                            label: 'Transaction ID',
                            hint: 'Enter transaction ID',
                            controller: controller.transactionIdController,
                            validator: controller.requiredValidator,
                          ),
                          const SizedBox(height: 16),
                          ReportTextField(
                            label: 'Amount',
                            hint: 'Enter amount',
                            controller: controller.amountController,
                            keyboardType: TextInputType.number,
                            onlyNumbers: true,
                            validator: controller.requiredValidator,
                          ),
                          const SizedBox(height: 16),
                        ],
                        ReportTextField(
                          label: 'Detailed Description',
                          hint: 'Explain the incident clearly',
                          controller: controller.descriptionController,
                          maxLines: 6,
                          validator: controller.requiredValidator,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: violet.withValues(alpha: 0.45),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.validateFullForm()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MailScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: violet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Generate Mail',
                        style: TextStyle(
                          fontSize: 18,
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
    );
  }
}

class GlowSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color glowColor;

  const GlowSectionCard({
    super.key,
    required this.title,
    required this.child,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: glowColor.withValues(alpha: 0.35),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.20),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: glowColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class GlowDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Color glowColor;

  const GlowDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.16),
                blurRadius: 18,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: items.contains(value) ? value : null,
            isExpanded: true,
            menuMaxHeight: 320,
            dropdownColor: const Color(0xFF162346),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: glowColor,
              size: 28,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF162346),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: glowColor.withValues(alpha: 0.28),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: glowColor,
                  width: 1.6,
                ),
              ),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class CategoryGlowCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryGlowCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    color.withValues(alpha: 0.22),
                    const Color(0xFF172349),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.80)
                : color.withValues(alpha: 0.25),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.30 : 0.12),
              blurRadius: isSelected ? 22 : 14,
              spreadRadius: isSelected ? 1.2 : 0.3,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.34),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.6,
                fontWeight: FontWeight.w800,
                height: 1.22,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              isSelected ? 'Selected' : 'Tap to choose',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? color : ReportScreen.textMuted,
                fontSize: 11.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}