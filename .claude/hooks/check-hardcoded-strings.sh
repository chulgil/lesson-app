#!/bin/bash
# check-hardcoded-strings.sh - PostToolUse Hook (Edit/Write)
# Dart 파일 수정 시 하드코딩된 한글 UI 텍스트를 검출하여 경고
# AppStrings 사용을 강제하기 위한 프로젝트 전용 hook

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    inp = d.get('tool_input', {})
    print(inp.get('file_path', ''))
except:
    pass
" 2>/dev/null)

# Dart 파일이 아니면 스킵
if [[ "$FILE_PATH" != *.dart ]]; then
    exit 0
fi

# features/ 디렉토리 안의 파일만 검사 (core/l10n은 제외)
if [[ "$FILE_PATH" != *"/features/"* ]]; then
    exit 0
fi

# 하드코딩 한글 텍스트 검출
# Text('한글...'), label: '한글...', hintText: '한글...' 패턴
VIOLATIONS=$(grep -n "Text('[가-힣]\|label: '[가-힣]\|hintText: '[가-힣]\|hint.*'[가-힣]\|title: '[가-힣]\|body: '[가-힣]\|return '[가-힣]" "$FILE_PATH" 2>/dev/null | grep -v "AppStrings\|// ignore-hardcode" | head -5)

if [[ -n "$VIOLATIONS" ]]; then
    echo "WARNING: Hardcoded Korean text detected in $FILE_PATH" >&2
    echo "Use AppStrings constants instead (HARD-GATE rule #2, i18n):" >&2
    echo "$VIOLATIONS" >&2
    echo "---" >&2
fi

exit 0
