import QtQuick 2.15
import QtMultimedia 5.15

Item {
    id: soundManager

    property bool soundEnabled: true
    property real volume: 0.5

    Component.onCompleted: {
        var savedEnabled = api.memory.get("soundEnabled")
        if (savedEnabled !== undefined) {
            soundEnabled = savedEnabled
        }

        var savedVolume = api.memory.get("soundVolume")
        if (savedVolume !== undefined) {
            volume = savedVolume
        }
    }

    onSoundEnabledChanged: {
        api.memory.set("soundEnabled", soundEnabled)
    }

    onVolumeChanged: {
        api.memory.set("soundVolume", volume)
    }

    SoundEffect {
        id: navigationSound
        source: soundEnabled ? "assets/soundeffect/game.wav" : ""
        volume: soundManager.volume
    }

    SoundEffect {
        id: collectionSound
        source: soundEnabled ? "assets/soundeffect/collect.wav" : ""
        volume: soundManager.volume
    }

    function playNavigation() {
        if (soundEnabled) navigationSound.play()
    }

    function playCollection() {
        if (soundEnabled) collectionSound.play()
    }

    function playSound(soundFile) {
        if (!soundEnabled) return

            var tempSound = Qt.createQmlObject('import QtMultimedia 5.15; SoundEffect { source: "' + soundFile + '"; volume: ' + volume + ' }', soundManager)
            if (tempSound) {
                tempSound.play()
                tempSound.Component.onDestruction.connect(function() {
                    tempSound.destroy()
                })
            }
    }

    function toggleSound() {
        soundEnabled = !soundEnabled
        return soundEnabled
    }
}
