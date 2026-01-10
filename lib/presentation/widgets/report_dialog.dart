import 'package:advertising_app/presentation/screen/all_add_real_estate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/report_provider.dart';
import 'package:advertising_app/core/utils/l10n_ext.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/my_color.dart';

class ReportDialog extends StatefulWidget {
  final String adType;
  final int adId;
  final String? token;

  const ReportDialog({
    super.key,
    required this.adType,
    required this.adId,
    this.token,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Map keys to localized strings
    final Map<String, String> reasons = {
      'inappropriate': context.l10n.report_reason_inappropriate,
      'spam': context.l10n.report_reason_spam,
      'misleading': context.l10n.report_reason_misleading,
      'duplicate': context.l10n.report_reason_duplicate,
      'fraud': context.l10n.report_reason_fraud,
      'wrong_category': context.l10n.report_reason_wrong_category,
      'other': context.l10n.report_reason_other,
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.report_ad_title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: MyColor.KTextColor,
                  ),
                ),
                SizedBox(height: 20.h),
                
                // Reason Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  style: TextStyle(
                    color: MyColor.KTextColor,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  ),
                  items: reasons.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: MyColor.KTextColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.please_select_all_fields; // Or specific error
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15.h),

                // Description Text Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: TextStyle(color: MyColor.KTextColor),
                  decoration: InputDecoration(
                    hintText: context.l10n.report_description_hint,
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.please_fill_required_fields;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),

                // Actions
                Consumer<ReportProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.l10n.report_cancel,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              provider.reportAd(
                                adType: widget.adType,
                                adId: widget.adId,
                                reason: _selectedReason!,
                                description: _descriptionController.text,
                                token: widget.token,
                                onSuccess: (message) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.l10n.report_success_message),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                onError: (message) {
                                  Navigator.of(context).pop(); // Close dialog on error? Maybe keep it open.
                                  // Let's keep it open on error usually, but for now I'll close it or show toast.
                                  // The user code seems to use SnackBar for errors.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyColor.KTextColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(context.l10n.report_submit),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
