import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/mausam_colors.dart';
import '../../../core/theme/mausam_spacing.dart';
import '../../../core/theme/mausam_typography.dart';
import '../../../state/mausam_state.dart';
import '../../../design_system/components/status_pill.dart';

class DeliveryOutcomeScreen extends StatefulWidget {
  final MausamState state;

  const DeliveryOutcomeScreen({super.key, required this.state});

  @override
  State<DeliveryOutcomeScreen> createState() => _DeliveryOutcomeScreenState();
}

class _DeliveryOutcomeScreenState extends State<DeliveryOutcomeScreen> {
  double _siteSlumpMm = 102.0;
  double _siteConcreteTempC = 33.8;
  String _selectedOutcome = 'accepted';
  bool _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    final batch = widget.state.selectedBatch;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery outcome log',
                    style: MausamTypography.headingXL.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: MausamColors.txtPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Quality audit & closed-loop verification',
                    style: MausamTypography.microOf(context),
                  ),
                ],
              ),
              StatusPill(
                label: batch.status,
                color: batch.status == 'DELIVERED' ? MausamColors.safe : MausamColors.info,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Batch Summary Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
              border: Border.all(color: MausamColors.brd(context)),
              boxShadow: MausamSpacing.shadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Batch #${batch.batchCode}',
                      style: MausamTypography.heading.copyWith(fontSize: 16, color: MausamColors.txtPrimary(context)),
                    ),
                    Text(
                      '${batch.volumeM3} m³ Mix',
                      style: MausamTypography.microOf(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(context, 'Plant slump', '${batch.initialSlumpMm.toInt()} mm'),
                    _buildSummaryItem(context, 'Target slump', '${batch.targetSlumpMm.toInt()} mm'),
                    _buildSummaryItem(context, 'Transit duration', '${batch.elapsedMinutes.toInt()} min'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quality Verification Form
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
              border: Border.all(color: MausamColors.brd(context)),
              boxShadow: MausamSpacing.shadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Site verification parameters',
                  style: MausamTypography.labelBoldOf(context).copyWith(
                    fontSize: 13,
                    color: MausamColors.txtPrimary(context),
                  ),
                ),
                const SizedBox(height: 14),

                // Site Slump Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Verified site slump', style: MausamTypography.bodyMediumOf(context)),
                    Text(
                      '${_siteSlumpMm.toInt()} mm',
                      style: MausamTypography.tabularOf(context).copyWith(
                        fontSize: 17,
                        color: _siteSlumpMm >= 95 ? MausamColors.safe : MausamColors.highRisk,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _siteSlumpMm,
                  min: 75.0,
                  max: 120.0,
                  divisions: 45,
                  activeColor: _siteSlumpMm >= 95 ? MausamColors.safe : MausamColors.highRisk,
                  onChanged: (v) => setState(() => _siteSlumpMm = v),
                ),
                const SizedBox(height: 10),

                // Site Concrete Temp Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Arrival concrete temp', style: MausamTypography.bodyMediumOf(context)),
                    Text(
                      '${_siteConcreteTempC.toStringAsFixed(1)}°C',
                      style: MausamTypography.tabularOf(context).copyWith(
                        fontSize: 17,
                        color: _siteConcreteTempC <= 35.0 ? MausamColors.safe : MausamColors.highRisk,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _siteConcreteTempC,
                  min: 28.0,
                  max: 42.0,
                  divisions: 28,
                  activeColor: _siteConcreteTempC <= 35.0 ? MausamColors.info : MausamColors.highRisk,
                  onChanged: (v) => setState(() => _siteConcreteTempC = v),
                ),
                const SizedBox(height: 14),

                // Quality Outcome Selector
                Text('Quality outcome', style: MausamTypography.labelBoldOf(context)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildOutcomePill('accepted', 'Accepted', MausamColors.safe),
                    const SizedBox(width: 8),
                    _buildOutcomePill('accepted_with_warning', 'Warning', MausamColors.watch),
                    const SizedBox(width: 8),
                    _buildOutcomePill('rejected', 'Rejected', MausamColors.highRisk),
                  ],
                ),
                const SizedBox(height: 16),

                // Financial Impact Assessment Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MausamColors.surfSecondary(context),
                    borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
                    border: Border.all(
                      color: _selectedOutcome == 'rejected'
                          ? MausamColors.highRisk.withValues(alpha: 0.35)
                          : MausamColors.safe.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedOutcome == 'rejected' ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                        size: 18,
                        color: _selectedOutcome == 'rejected' ? MausamColors.highRisk : MausamColors.safe,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedOutcome == 'rejected' ? 'ESTIMATED BATCH LOSS' : 'ESTIMATED AVOIDED LOSS',
                              style: MausamTypography.microOf(context).copyWith(
                                color: _selectedOutcome == 'rejected' ? MausamColors.highRisk : MausamColors.safe,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _selectedOutcome == 'rejected'
                                  ? '₹2.41 Lakhs (Material & Truck Transit)'
                                  : '₹1.68 Lakhs (Prevented transit failure)',
                              style: MausamTypography.labelBoldOf(context).copyWith(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitted
                        ? null
                        : () async {
                            await widget.state.submitOutcome(
                              outcome: _selectedOutcome,
                              siteSlumpMm: _siteSlumpMm,
                              transitMinutes: batch.elapsedMinutes,
                              concreteTempC: _siteConcreteTempC,
                              rejectionReason: _selectedOutcome == 'rejected' ? 'Severe slump degradation' : null,
                            );
                            setState(() => _isSubmitted = true);
                          },
                    icon: Icon(_isSubmitted ? LucideIcons.check : LucideIcons.send, size: 15),
                    label: Text(_isSubmitted ? 'Outcome logged & piped to ML' : 'Record outcome & retrain model'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitted ? MausamColors.safe : MausamColors.info,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ML Retraining Loop Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: MausamColors.surf(context),
              borderRadius: BorderRadius.circular(MausamSpacing.radiusDataSurfaces),
              border: Border.all(color: MausamColors.brd(context)),
              boxShadow: MausamSpacing.shadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.gitFork, size: 14, color: MausamColors.info),
                        const SizedBox(width: 6),
                        Text(
                          'ML feedback loop',
                          style: MausamTypography.labelBoldOf(context).copyWith(
                            color: MausamColors.info,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const StatusPill(label: 'PIPELINE ACTIVE', color: MausamColors.safe),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Every verified delivery outcome automatically appends ground-truth concrete slump, ambient weather, and transit duration to the retraining dataset to update GBR/RF risk weights.',
                  style: MausamTypography.bodyOf(context).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  'Training dataset size: ${1200 + widget.state.outcomes.length} records · Model: GBR-v1.2.0',
                  style: MausamTypography.microOf(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MausamTypography.microOf(context).copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: MausamTypography.labelBoldOf(context).copyWith(fontSize: 12.5)),
      ],
    );
  }

  Widget _buildOutcomePill(String id, String label, Color color) {
    final isSelected = _selectedOutcome == id;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedOutcome = id),
        borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : MausamColors.surfSecondary(context),
            borderRadius: BorderRadius.circular(MausamSpacing.radiusControls),
            border: Border.all(
              color: isSelected ? color : MausamColors.brdSubtle(context),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: MausamTypography.microOf(context).copyWith(
              color: isSelected ? color : MausamColors.txtSecondary(context),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
