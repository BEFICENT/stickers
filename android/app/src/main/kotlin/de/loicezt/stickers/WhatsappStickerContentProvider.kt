package de.loicezt.stickers

import android.content.res.AssetFileDescriptor
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import dev.applicazza.flutter.plugins.whatsapp_stickers_plus.StickerContentProvider
import java.io.File

class WhatsappStickerContentProvider : StickerContentProvider() {
    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor? {
        val cursor = super.query(uri, projection, selection, selectionArgs, sortOrder)
        return normalizeCursor(uri, cursor)
    }

    override fun openAssetFile(uri: Uri, mode: String): AssetFileDescriptor? {
        return super.openAssetFile(resolveAssetUri(uri), mode)
    }

    override fun getType(uri: Uri): String? {
        if (uri.pathSegments.firstOrNull() == "stickers_asset" &&
            uri.lastPathSegment?.endsWith(".png", ignoreCase = true) == true
        ) {
            return "image/png"
        }
        return super.getType(uri)
    }

    private fun normalizeCursor(uri: Uri, source: Cursor?): Cursor? {
        if (source == null) return null
        return when (uri.pathSegments.firstOrNull()) {
            "metadata" -> normalizeMetadata(source)
            "stickers" -> normalizeStickers(source)
            else -> source
        }
    }

    private fun normalizeMetadata(source: Cursor): Cursor {
        val columns = source.columnNames
        val iconIndex = source.getColumnIndex("sticker_pack_icon")
        val result = MatrixCursor(columns, source.count)
        source.use { cursor ->
            while (cursor.moveToNext()) {
                val row = copyRow(cursor)
                row[iconIndex] = shortFileName(cursor.getString(iconIndex))
                OPTIONAL_METADATA_COLUMNS.forEach { column ->
                    val index = cursor.getColumnIndex(column)
                    if (index >= 0 && cursor.isNull(index)) row[index] = ""
                }
                result.addRow(row)
            }
        }
        return result
    }

    private fun normalizeStickers(source: Cursor): Cursor {
        val result = MatrixCursor(
            arrayOf("sticker_file_name", "sticker_emoji", ACCESSIBILITY_COLUMN),
            source.count
        )
        source.use { cursor ->
            while (cursor.moveToNext()) {
                result.addRow(
                    arrayOf<Any?>(shortFileName(cursor.getString(0)), cursor.getString(1), null)
                )
            }
        }
        return result
    }

    private fun resolveAssetUri(uri: Uri): Uri {
        val pathSegments = uri.pathSegments
        if (pathSegments.size != 3 || pathSegments.first() != "stickers_asset") {
            return uri
        }
        val identifier = pathSegments[1]
        val requestedFileName = pathSegments[2]
        val storedFileName = findStoredFileName(identifier, requestedFileName) ?: return uri
        return Uri.Builder()
            .scheme(uri.scheme)
            .authority(uri.authority)
            .appendPath("stickers_asset")
            .appendPath(identifier)
            .appendPath(storedFileName)
            .build()
    }

    private fun findStoredFileName(identifier: String, requestedFileName: String): String? {
        val metadataUri = Uri.Builder()
            .scheme("content")
            .authority(requireNotNull(context).packageName + ".stickercontentprovider")
            .appendPath("metadata")
            .appendPath(identifier)
            .build()
        super.query(metadataUri, null, null, null, null)?.use { cursor ->
            val iconIndex = cursor.getColumnIndex("sticker_pack_icon")
            if (cursor.moveToFirst()) {
                val stored = cursor.getString(iconIndex)
                if (shortFileName(stored) == requestedFileName) return stored
            }
        }

        val stickersUri = metadataUri.buildUpon()
            .path(null)
            .appendPath("stickers")
            .appendPath(identifier)
            .build()
        super.query(stickersUri, null, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                val stored = cursor.getString(0)
                if (shortFileName(stored) == requestedFileName) return stored
            }
        }
        return null
    }

    private fun shortFileName(storedFileName: String): String {
        val decoded = storedFileName
            .replace("mzn_fd_", File.separator)
            .replace("mzn_ad_", File.separator)
        return File(decoded).name
    }

    private fun copyRow(cursor: Cursor): Array<Any?> {
        return Array(cursor.columnCount) { index ->
            when (cursor.getType(index)) {
                Cursor.FIELD_TYPE_NULL -> null
                Cursor.FIELD_TYPE_INTEGER -> cursor.getLong(index)
                Cursor.FIELD_TYPE_FLOAT -> cursor.getDouble(index)
                Cursor.FIELD_TYPE_BLOB -> cursor.getBlob(index)
                else -> cursor.getString(index)
            }
        }
    }

    private companion object {
        const val ACCESSIBILITY_COLUMN = "sticker_accessibility_text"
        val OPTIONAL_METADATA_COLUMNS = setOf(
            "sticker_pack_publisher_email",
            "sticker_pack_publisher_website",
            "sticker_pack_privacy_policy_website",
            "sticker_pack_license_agreement_website"
        )
    }
}
