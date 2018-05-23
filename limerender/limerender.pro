contains(CONFIG,release) {
	TARGET = limerender
} else {
	TARGET = limerenderd
}

TEMPLATE = lib

contains(CONFIG, static_build){
    CONFIG += staticlib
}

!contains(CONFIG, staticlib){
    CONFIG += lib
    CONFIG += dll
}

CONFIG += create_prl
CONFIG += link_prl

macx{
    CONFIG  -= dll
    CONFIG  += lib_bundle
    CONFIG  += plugin
}

DEFINES += LIMEREPORT_EXPORTS

contains(CONFIG, staticlib){
    DEFINES += HAVE_STATIC_BUILD
    message(STATIC_BUILD)
    DEFINES -= LIMEREPORT_EXPORTS
}

EXTRA_FILES += \
    $$PWD/../limereport/lrglobal.cpp \
    $$PWD/../limereport/lrglobal.h \
    $$PWD/../limereport/lrdatasourcemanagerintf.h \
    $$PWD/../limereport/lrreportengine.h \
    $$PWD/../limereport/lrscriptenginemanagerintf.h \
    $$PWD/../limereport/lrcallbackdatasourceintf.h \
    $$PWD/../limereport/lrpreviewreportwidget.h

include(limerender.pri)

unix:{
    DESTDIR  = $${DEST_LIBS}
    linux{
        QMAKE_POST_LINK += mkdir -p $$quote($${DEST_INCLUDE_DIR}) $$escape_expand(\\n\\t) # qmake need make mkdir -p on subdirs more than root/
        for(FILE,EXTRA_FILES){
            QMAKE_POST_LINK += $$QMAKE_COPY $$quote($$FILE) $$quote($${DEST_INCLUDE_DIR}) $$escape_expand(\\n\\t) # inside of libs make /include/files
        }
    }
    macx{
        for(FILE,EXTRA_FILES){
            QMAKE_POST_LINK += $$QMAKE_COPY $$quote($$FILE) $$quote($${DEST_INCLUDE_DIR}) $$escape_expand(\\n\\t)
        }
        QMAKE_POST_LINK += mkdir -p $$quote($${DESTDIR}/include) $$escape_expand(\\n\\t)
    }
    QMAKE_POST_LINK += $$QMAKE_COPY_DIR $$quote($${DEST_INCLUDE_DIR}) $$quote($${DESTDIR})
}

win32 {
    EXTRA_FILES ~= s,/,\\,g
    BUILD_DIR ~= s,/,\\,g
    DESTDIR = $${DEST_LIBS}
    DEST_DIR = $$DESTDIR/include
    DEST_DIR ~= s,/,\\,g
    DEST_INCLUDE_DIR ~= s,/,\\,g

    for(FILE,EXTRA_FILES){
        QMAKE_POST_LINK += $$QMAKE_COPY \"$$FILE\" \"$${DEST_INCLUDE_DIR}\" $$escape_expand(\\n\\t)
    }
    QMAKE_POST_LINK += $$QMAKE_COPY_DIR \"$${DEST_INCLUDE_DIR}\" \"$${DEST_DIR}\"
}

contains(CONFIG,zint){
    message(zint)
    INCLUDEPATH += $$ZINT_PATH/backend $$ZINT_PATH/backend_qt
    DEPENDPATH += $$ZINT_PATH/backend $$ZINT_PATH/backend_qt
	LIBS += -L$${DEST_LIBS}
	contains(CONFIG,release) {
		LIBS += -lQtZint
	} else {
		LIBS += -lQtZintd
	}
}

####Automatically build required translation files (*.qm)

contains(CONFIG,build_translations){
    LANGUAGES = ru es_ES ar

    defineReplace(prependAll) {
        for(a,$$1):result += $$2$${a}$$3
        return($$result)
    }

    TRANSLATIONS = $$prependAll(LANGUAGES, \"$$TRANSLATIONS_PATH/limereport_,.ts\")

    qtPrepareTool(LUPDATE, lupdate)

greaterThan(QT_MAJOR_VERSION, 4) {
    ts.commands = $$LUPDATE $$shell_quote($$PWD) -ts $$TRANSLATIONS
}
lessThan(QT_MAJOR_VERSION, 5){
    ts.commands = $$LUPDATE $$quote($$PWD) -ts $$TRANSLATIONS
}
    TRANSLATIONS_FILES =
    qtPrepareTool(LRELEASE, lrelease)
    for(tsfile, TRANSLATIONS) {
        qmfile = $$tsfile
        qmfile ~= s,".ts\"$",".qm\"",
        qm.commands += $$LRELEASE -removeidentical $$tsfile -qm $$qmfile $$escape_expand(\\n\\t)
        tmp_command = $$LRELEASE -removeidentical $$tsfile -qm $$qmfile $$escape_expand(\\n\\t)
        TRANSLATIONS_FILES += $$qmfile
    }
    qm.depends = ts
    OTHER_FILES += $$TRANSLATIONS
    QMAKE_EXTRA_TARGETS += qm ts
    POST_TARGETDEPS +=  qm
}

#### EN AUTOMATIC TRANSLATIONS