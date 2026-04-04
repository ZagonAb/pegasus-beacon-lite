import QtQuick 2.15

QtObject {
    id: root

    readonly property var virtualCollections: [
        {
            name: "NOW",
            shortName: "now",
            isVirtual: true,
            virtualType: "recent",
            summary: "Recently played"
        },
        {
            name: "FAVS",
            shortName: "favs",
            isVirtual: true,
            virtualType: "favorites",
            summary: "Your favorites"
        }
    ]

    function gamesForVirtual(virtualType) {
        var all = api.allGames.toVarArray()
        if (virtualType === "favorites") {
            return all.filter(function(g) { return g.favorite })
        }
        if (virtualType === "recent") {
            var played = all.filter(function(g) {
                return g.lastPlayed && !isNaN(g.lastPlayed.getTime()) && g.lastPlayed.getTime() > 0
            })
            played.sort(function(a, b) { return b.lastPlayed - a.lastPlayed })
            return played.slice(0, 50)
        }
        return []
    }

    function buildFullList(customOrder) {
        var result = []

        for (var i = 0; i < virtualCollections.length; i++) {
            var vc = virtualCollections[i]
            result.push({
                name: vc.name,
                shortName: vc.shortName,
                summary: vc.summary,
                isVirtual: true,
                virtualType: vc.virtualType,
                realIndex: -1
            })
        }

        var count = api.collections.count
        var useCustom = customOrder
                        && Array.isArray(customOrder)
                        && customOrder.length === count

        for (var j = 0; j < count; j++) {
            var realIdx = useCustom ? customOrder[j] : j
            // Guardia: índice fuera de rango (colecciones añadidas/eliminadas)
            if (realIdx < 0 || realIdx >= count) realIdx = j
            var col = api.collections.get(realIdx)
            if (!col) continue
            result.push({
                name: col.name,
                shortName: col.shortName,
                summary: col.summary,
                isVirtual: false,
                virtualType: "",
                realIndex: realIdx
            })
        }

        return result
    }
}
