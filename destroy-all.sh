#!/bin/bash
PROJECT_ID="shay-project-477811"
CLUSTER_NAME="shay-project-cluster"
REGION="us-central1"

echo "🗑️ מוחק את הקלאסטר וחוסך כסף..."
gcloud container clusters delete $CLUSTER_NAME --region $REGION --quiet

echo "💸 הקלאסטר נמחק בהצלחה!"