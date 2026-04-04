.pragma library

var ASPECT_RATIOS = {
    "1:1":    { widthRatio: 1,   heightRatio: 1   },
    "4:3":    { widthRatio: 4,   heightRatio: 3   },
    "3:4":    { widthRatio: 3,   heightRatio: 4   },
    "8:7":    { widthRatio: 8,   heightRatio: 7   },
    "3:5":    { widthRatio: 3,   heightRatio: 5   },
    "2:3":    { widthRatio: 2,   heightRatio: 3   },
    "custom": { widthRatio: 1,   heightRatio: 1.5 }
}

var VIRTUAL_COLLECTION_RATIO = "2:3"

function getRatio(key) {
    if (!key || key === "") return null
    return ASPECT_RATIOS[key] || null
}

function fitToRatio(cW, cH, key) {
    var r = getRatio(key)
    if (!r) return { width: cW, height: cH }
    var targetAspect = r.widthRatio / r.heightRatio
    var w = cW
    var h = Math.round(cW / targetAspect)
    if (h > cH) { h = cH; w = Math.round(cH * targetAspect) }
    return { width: w, height: h }
}

function gridCellHeight(cellWidth, key) {
    var r = getRatio(key)
    if (!r) return Math.floor(cellWidth * 1.45)
    return Math.floor(cellWidth * (r.heightRatio / r.widthRatio))
}

function listViewHeights(featuredW, thumbW, key) {
    var r = getRatio(key)
    if (!r) {
        return {
            featuredH: Math.round(featuredW * (450 / 280)),
            thumbH:    Math.round(thumbW    * (290 / 130))
        }
    }
    var aspect = r.heightRatio / r.widthRatio
    return {
        featuredH: Math.round(featuredW * aspect),
        thumbH:    Math.round(thumbW    * aspect)
    }
}

function isSpecialCollection(collectionEntry) {
    if (!collectionEntry) return false
    return collectionEntry.isVirtual === true &&
           (collectionEntry.shortName === "now" || collectionEntry.shortName === "favs")
}

// DEPRECATED: ya no se usa desde las vistas. Mantenido solo por compatibilidad.
// La resolución del ratio se hace directamente en GameGridView/GameListView
// usando el ratioMap recibido como prop.
function ratioForCollection(collectionEntry) {
    if (!collectionEntry) return ""
    if (isSpecialCollection(collectionEntry)) return VIRTUAL_COLLECTION_RATIO
    return ""
}

function getUniqueGenresFromGames(maxGenres) {
    var uniqueGenres = new Set();
    var genreCount = {};

    for (var i = 0; i < api.allGames.count; i++) {
        var game = api.allGames.get(i);
        if (game && game.genre) {
            var cleanedGenres = cleanAndSplitGenres(game.genre);
            cleanedGenres.forEach(function(genre) {
                if (genre && genre.trim() !== "") {
                    var cleanGenre = genre.trim();
                    uniqueGenres.add(cleanGenre);

                    if (!genreCount[cleanGenre]) {
                        genreCount[cleanGenre] = 0;
                    }
                    genreCount[cleanGenre]++;
                }
            });
        }
    }

    var genresArray = Array.from(uniqueGenres);
    genresArray.sort(function(a, b) {
        return (genreCount[b] || 0) - (genreCount[a] || 0);
    });

    if (maxGenres && maxGenres > 0) {
        return genresArray.slice(0, maxGenres);
    }

    return genresArray;
}

function cleanAndSplitGenres(genreText) {
    if (!genreText) return [];

    var separators = [",", "/", "-", "&", "|", ";"];
    var allParts = [genreText];

    for (var i = 0; i < separators.length; i++) {
        var separator = separators[i];
        var newParts = [];

        for (var j = 0; j < allParts.length; j++) {
            var part = allParts[j];
            var splitParts = part.split(separator);

            for (var k = 0; k < splitParts.length; k++) {
                newParts.push(splitParts[k]);
            }
        }
        allParts = newParts;
    }

    var cleanedParts = [];
    for (var l = 0; l < allParts.length; l++) {
        var cleaned = allParts[l].trim();

        if (cleaned.length > 0 &&
            cleaned.toLowerCase() !== "and" &&
            cleaned.toLowerCase() !== "or" &&
            cleaned.toLowerCase() !== "game" &&
            cleaned.length > 2) {
            cleanedParts.push(cleaned);
            }
    }

    return cleanedParts;
}

function getFirstGenre(gameData) {
    if (!gameData || !gameData.genre) return "Unknown";

    var cleanedGenres = cleanAndSplitGenres(gameData.genre);
    return cleanedGenres.length > 0 ? cleanedGenres[0] : "Unknown";
}
