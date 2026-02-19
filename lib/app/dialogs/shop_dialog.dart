part of '../../main.dart';

Future<void> showShopDialog(
  BuildContext context,
  MonsterTapGame game,
) async {
  await game.loadCustomizationProgress();
  if (!context.mounted) return;

  var previewState = 'idle';
  var selectedSkinId = game.selectedMonsterId;
  String? selectedAccessoryId;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final coins = game.totalCoins;
          final skins = game.availableMonsters;
          final selectedSkin = skins.firstWhere(
            (skin) => skin.id == selectedSkinId,
            orElse: () => skins.first,
          );
          final selectedSkinUnlocked = game.isMonsterUnlocked(selectedSkin.id);
          final selectedSkinEquipped = game.isMonsterSelected(selectedSkin.id);
          final skinAssetFolder = selectedSkin.assetFolder;
          final skinPreviewPath =
              'assets/images/characters/$skinAssetFolder/$previewState.png';

          final accessories = game.accessoriesFor(
            level: GameLevel.level1,
            monsterId: selectedSkin.id,
          );
          final equippedAccessoryId = game.equippedAccessoryIdForTarget(
            level: GameLevel.level1,
            monsterId: selectedSkin.id,
          );
          if (selectedAccessoryId == null ||
              !accessories.any((item) => item.id == selectedAccessoryId)) {
            selectedAccessoryId = equippedAccessoryId;
            if (selectedAccessoryId == null && accessories.isNotEmpty) {
              selectedAccessoryId = accessories.first.id;
            }
          }
          final selectedAccessory = selectedAccessoryId == null
              ? null
              : accessories.firstWhere((item) => item.id == selectedAccessoryId);
          final selectedAccessoryPreviewPath = selectedAccessory == null
              ? null
              : 'assets/images/${selectedAccessory.assetPath}';

          return AlertDialog(
            backgroundColor: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text(
              'Shop',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Coins: $coins',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0x33000000),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x55FFFFFF)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                skinPreviewPath,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (selectedAccessoryPreviewPath != null)
                              Positioned(
                                top: 10,
                                child: SizedBox(
                                  width: 140,
                                  height: 82,
                                  child: Opacity(
                                    opacity: 0.95,
                                    child: Image.asset(
                                      selectedAccessoryPreviewPath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Idle'),
                            selected: previewState == 'idle',
                            onSelected: (_) =>
                                setDialogState(() => previewState = 'idle'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Happy'),
                            selected: previewState == 'happy',
                            onSelected: (_) =>
                                setDialogState(() => previewState = 'happy'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Sad'),
                            selected: previewState == 'sad',
                            onSelected: (_) =>
                                setDialogState(() => previewState = 'sad'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Monster Skins',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...skins.map(
                        (skin) {
                          final unlocked = game.isMonsterUnlocked(skin.id);
                          final equipped = game.isMonsterSelected(skin.id);
                          final selected = selectedSkinId == skin.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              tileColor: selected
                                  ? const Color(0x2242A5F5)
                                  : const Color(0x22000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFF42A5F5)
                                      : const Color(0x33FFFFFF),
                                ),
                              ),
                              title: Text(
                                skin.label,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                unlocked
                                    ? (equipped ? 'Equipped' : 'Owned')
                                    : '${skin.unlockCost} coins',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  selectedSkinId = skin.id;
                                  selectedAccessoryId = null;
                                });
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (!selectedSkinUnlocked)
                            ElevatedButton(
                              onPressed: coins >= selectedSkin.unlockCost
                                  ? () async {
                                      final ok =
                                          await game.unlockMonster(selectedSkin.id);
                                      if (!ok) return;
                                      await game.selectMonster(selectedSkin.id);
                                      await game.loadCustomizationProgress();
                                      setDialogState(() {
                                        selectedSkinId = game.selectedMonsterId;
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF43A047),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Buy & Equip'),
                            ),
                          if (selectedSkinUnlocked)
                            ElevatedButton(
                              onPressed: selectedSkinEquipped
                                  ? null
                                  : () async {
                                      await game.selectMonster(selectedSkin.id);
                                      await game.loadCustomizationProgress();
                                      setDialogState(() {
                                        selectedSkinId = game.selectedMonsterId;
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF42A5F5),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                selectedSkinEquipped ? 'Equipped' : 'Equip',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Accessories',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (accessories.isEmpty)
                        const Text(
                          'No accessories for this skin yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ...accessories.map(
                        (item) {
                          final unlocked = game.isAccessoryUnlocked(item.id);
                          final equipped = game.isAccessoryEquipped(
                            accessoryId: item.id,
                            level: GameLevel.level1,
                            monsterId: selectedSkin.id,
                          );
                          final selected = selectedAccessoryId == item.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              tileColor: selected
                                  ? const Color(0x2242A5F5)
                                  : const Color(0x22000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFF42A5F5)
                                      : const Color(0x33FFFFFF),
                                ),
                              ),
                              leading: SizedBox(
                                width: 42,
                                height: 42,
                                child: Image.asset(
                                  'assets/images/${item.assetPath}',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              title: Text(
                                item.label,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                unlocked
                                    ? (equipped ? 'Equipped' : 'Owned')
                                    : '${item.cost} coins',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  selectedAccessoryId = item.id;
                                });
                              },
                              trailing: unlocked
                                  ? ElevatedButton(
                                      onPressed: equipped
                                          ? null
                                          : () async {
                                              await game.setAccessoryEquipped(
                                                item.id,
                                                level: GameLevel.level1,
                                                monsterId: selectedSkin.id,
                                              );
                                              await game.loadCustomizationProgress();
                                              setDialogState(() {
                                                selectedAccessoryId = item.id;
                                              });
                                            },
                                      child: Text(
                                        equipped ? 'Equipped' : 'Equip',
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: coins >= item.cost
                                          ? () async {
                                              final ok =
                                                  await game.unlockAccessory(item.id);
                                              if (!ok) return;
                                              await game.setAccessoryEquipped(
                                                item.id,
                                                level: GameLevel.level1,
                                                monsterId: selectedSkin.id,
                                              );
                                              await game.loadCustomizationProgress();
                                              setDialogState(() {
                                                selectedAccessoryId = item.id;
                                              });
                                            }
                                          : null,
                                      child: const Text('Buy'),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF81C784)),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
